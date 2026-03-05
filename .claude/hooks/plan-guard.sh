#!/bin/bash
# ============================================================
# [UserPromptSubmit Hook] 계획 없이 작업 시작 방지
# ============================================================
# 매칭 조건 활용:
#   1. 키워드 → 개발 관련인지 필터링
#   2. 의도 파악 → 새 작업 vs 이어서 vs 단순 수정 판별
#   3. 작업 위치 → 관련 계획이 있는지 파일 경로로 탐색
# ============================================================

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

trap 'exit 0' ERR

if ! source "$SCRIPT_DIR/lib/matcher.sh" 2>/dev/null; then
  echo "[plan-guard] 매칭 라이브러리 로드 실패 — 바이패스" >&2
  exit 0
fi

# ── 함수 정의 ──

_check_init_status() {
  local INIT_MARKER="$CWD/.claude/.initialized"
  local SETUP_IN_PROGRESS="$CWD/.claude/.setup-in-progress"

  [ -f "$INIT_MARKER" ] && return 0

  # /setup 진행 중이면 통과
  [ -f "$SETUP_IN_PROGRESS" ] && exit 0

  # .claude/hooks 존재 + .initialized 없음 = 세팅 미완료
  if [ -d "$CWD/.claude/hooks" ]; then
    # /setup 명령이면 통과
    if echo "$PROMPT" | grep -qE '^\s*/setup(\s|$)'; then
      exit 0
    fi

    # 설치 검증: 필수 파일 존재 확인
    local MISSING=""
    [ ! -f "$CWD/.claude/settings.json" ] && MISSING="${MISSING}  · .claude/settings.json"$'\n'

    local HOOK_COUNT
    HOOK_COUNT=$(find "$CWD/.claude/hooks" -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
    [ "$HOOK_COUNT" -eq 0 ] && MISSING="${MISSING}  · .claude/hooks/*.sh (Hook 스크립트)"$'\n'

    [ ! -d "$CWD/.claude/skills" ] && MISSING="${MISSING}  · .claude/skills/ (스킬 디렉토리)"$'\n'

    if [ -n "$MISSING" ]; then
      cat <<MSG
───────────────────────────────────────────
⚠️ [설치 불완전] 일부 파일이 누락되었습니다
───────────────────────────────────────────

누락된 항목:
${MISSING}
💡 dev_sys_template에서 다시 설치하거나,
   install.sh를 실행하여 설치를 완료하세요.

[시스템 지시] 설치가 불완전합니다. 사용자에게 위 누락 항목을 안내하고 재설치를 도와주세요.
───────────────────────────────────────────
MSG
      exit 0
    fi

    # 설치 완료이나 /setup 미실행
    cat <<'MSG'
───────────────────────────────────────────
🚀 [세팅 미완료] /setup을 실행해주세요
───────────────────────────────────────────

파일 설치는 완료되었지만, 프로젝트 초기 설정이 필요합니다.

👉 /setup 을 실행하면 5단계 대화형 위저드로
   프로젝트 전체 세팅을 완료합니다.
   (비전 수집 → 환경 분석 → 워크플로우 → 개발 계획 → 환경 세팅)

[시스템 지시] 초기 세팅이 완료되지 않았습니다. 사용자에게 /setup 실행을 안내하세요. 코드 작성이나 다른 작업을 수행하지 마세요.
───────────────────────────────────────────
MSG
    exit 0
  fi
}

_find_plan_status() {
  IN_PROGRESS=""
  PENDING_APPROVAL=""
  ALL_COMPLETED=true

  for checklist in "$PLANS_DIR"/*/CHECKLIST.md; do
    [ -f "$checklist" ] || continue
    if grep -q "🟡 진행 중" "$checklist" 2>/dev/null; then
      IN_PROGRESS=$(basename "$(dirname "$checklist")")
      ALL_COMPLETED=false
      break
    elif grep -q "🔴 시작 전" "$checklist" 2>/dev/null; then
      PENDING_APPROVAL=$(basename "$(dirname "$checklist")")
      ALL_COMPLETED=false
    elif grep -q "🟢 완료" "$checklist" 2>/dev/null; then
      : # 완료 — ALL_COMPLETED 유지
    else
      ALL_COMPLETED=false
    fi
  done
}

_display_progress() {
  local PLAN_DIR="$PLANS_DIR/$IN_PROGRESS"
  local CHECKLIST_FILE="$PLAN_DIR/CHECKLIST.md"
  local TOTAL_TASKS=0 DONE_TASKS=0 CURRENT_PHASE="" NEXT_ITEMS=""

  if [ -f "$CHECKLIST_FILE" ]; then
    TOTAL_TASKS=$(grep -c '^\s*- \[' "$CHECKLIST_FILE" 2>/dev/null || echo "0")
    DONE_TASKS=$(grep -c '^\s*- \[x\]' "$CHECKLIST_FILE" 2>/dev/null || echo "0")
    CURRENT_PHASE=$(grep -m1 '^\s*- \[ \] Phase' "$CHECKLIST_FILE" 2>/dev/null | sed 's/^.*- \[ \] //')

    if [ -n "$CURRENT_PHASE" ]; then
      NEXT_ITEMS=$(awk '
        /- \[ \] Phase/ { if (found) exit; found=1; next }
        found && /- \[ \]/ { gsub(/^[[:space:]]*- \[ \] /, "  · "); print; count++; if(count>=5) exit }
        found && /- \[ \] Phase/ { exit }
      ' "$CHECKLIST_FILE" 2>/dev/null)
    fi
  fi

  cat <<MSG
───────────────────────────────────────────
📋 [컨텍스트] ${IN_PROGRESS} (🟡 진행 중)
───────────────────────────────────────────

진행: ${DONE_TASKS}/${TOTAL_TASKS} 완료
MSG

  [ -n "$CURRENT_PHASE" ] && echo "현재: ${CURRENT_PHASE}"
  if [ -n "$NEXT_ITEMS" ]; then
    echo ""
    echo "남은 작업:"
    echo "$NEXT_ITEMS"
  fi

  cat <<MSG

📂 docs/plans/${IN_PROGRESS}/
   → PLAN.md, CHECKLIST.md를 읽고 이어서 작업하세요.
───────────────────────────────────────────
MSG
}

# ── main: 가드 → 분류 → 분기 ──

# 가드: 초기화 + 바이패스
_check_init_status

if echo "$PROMPT" | grep -qE '^\s*/[a-zA-Z]'; then
  exit 0
fi

if echo "$PROMPT" | grep -qE '^\s*(간단|직접|바로)\s*[:：]'; then
  exit 0
fi

if $_HAS_CONFIG 2>/dev/null; then
  GLOBAL_REQUIRE=$(cfg_get_general "require_plan" 2>/dev/null)
  [ "$GLOBAL_REQUIRE" = "false" ] && exit 0
fi

# 짧은 프롬프트 + 완료 상태 감지
PROMPT_TRIMMED=$(echo "$PROMPT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
PLANS_DIR="$CWD/docs/plans"

if [ "${#PROMPT_TRIMMED}" -le 20 ] && [ -d "$PLANS_DIR" ]; then
  _HAS_ACTIVE=false
  _HAS_COMPLETED=false
  for _cl in "$PLANS_DIR"/*/CHECKLIST.md; do
    [ -f "$_cl" ] || continue
    if grep -q "🟡 진행 중" "$_cl" 2>/dev/null; then
      _HAS_ACTIVE=true
      break
    elif grep -q "🟢 완료" "$_cl" 2>/dev/null; then
      _HAS_COMPLETED=true
    fi
  done

  if ! $_HAS_ACTIVE && $_HAS_COMPLETED; then
    cat <<'MSG'
[시스템 지시] 짧은 응답이 감지되었으며, 활성 계획이 없습니다 (모든 계획 🟢 완료).

⚠️ 코드 변경이 필요한 상황이라면 바로 실행하지 마세요.
반드시 AskUserQuestion 도구로 사용자에게 먼저 확인하세요:
→ "간단한 작업인데 /plan-manager 없이 바로 진행할까요?"
  선택지: "바로 진행" / "/plan-manager로 계획 수립"

단순 대화(질문 답변, 설명 등)는 그대로 진행하세요.
MSG
    exit 0
  fi
fi

# 키워드 + 의도 분류
KEYWORD_TYPE=$(match_keywords "$PROMPT")
[ "$KEYWORD_TYPE" = "none" ] && exit 0

INTENT=$(detect_intent "$PROMPT")

if ! intent_requires_plan "$INTENT"; then
  if [ -d "$PLANS_DIR" ]; then
    for checklist in "$PLANS_DIR"/*/CHECKLIST.md; do
      [ -f "$checklist" ] || continue
      if grep -q "🟡 진행 중" "$checklist" 2>/dev/null; then
        PLAN_NAME=$(basename "$(dirname "$checklist")")
        echo "───────────────────────────────────────────"
        echo "📋 참고: 진행 중인 작업 '${PLAN_NAME}'이 있습니다."
        echo "───────────────────────────────────────────"
        break
      fi
    done
  fi
  exit 0
fi

# 파일 경로 관련 계획 탐색
FILE_MENTION=$(echo "$PROMPT" | grep -oE '[a-zA-Z0-9_/.-]+\.(ts|tsx|js|jsx|py|vue|svelte|css|json)' | head -1)
if [ -n "$FILE_MENTION" ] && [ -d "$PLANS_DIR" ]; then
  for plan in "$PLANS_DIR"/*/PLAN.md; do
    [ -f "$plan" ] || continue
    if grep -q "$FILE_MENTION" "$plan" 2>/dev/null; then
      RELATED_PLAN=$(basename "$(dirname "$plan")")
      cat <<MSG
───────────────────────────────────────────
📋 [계획 관리] 관련 계획 발견
───────────────────────────────────────────

언급된 파일: ${FILE_MENTION}
관련 계획:   ${RELATED_PLAN}

📂 docs/plans/${RELATED_PLAN}/
   → PLAN.md, CONTEXT.md, CHECKLIST.md 를 확인하세요.
───────────────────────────────────────────
MSG
      exit 0
    fi
  done
fi

# plans 디렉토리 없음
if [ ! -d "$PLANS_DIR" ]; then
  cat <<'MSG'
───────────────────────────────────────────
⚠️ [계획 관리] 계획서가 없습니다
───────────────────────────────────────────

💡 /plan-manager 로 3문서를 생성하면 체계적으로 작업할 수 있습니다.
───────────────────────────────────────────
MSG
  exit 0
fi

# 분류 → 분기
_find_plan_status

if [ -n "$PENDING_APPROVAL" ] && [ -z "$IN_PROGRESS" ]; then
  cat <<MSG
───────────────────────────────────────────
⚠️ [계획 관리] 승인 대기 중인 계획이 있습니다
───────────────────────────────────────────

계획: ${PENDING_APPROVAL} (🔴 시작 전)

📂 docs/plans/${PENDING_APPROVAL}/
   → 승인 후 CHECKLIST.md 상태를 🟡 진행 중 으로 변경하세요.
───────────────────────────────────────────
MSG
  exit 0
fi

if [ -n "$IN_PROGRESS" ]; then
  _display_progress
else
  DETECTED_INTENT=$(detect_intent "$PROMPT")
  INTENT_LABEL=$(intent_to_label "$DETECTED_INTENT")

  if $ALL_COMPLETED; then
    cat <<MSG
[시스템 지시] 모든 계획이 완료된 상태에서 새 작업 요청이 감지되었습니다.
감지된 의도: "${INTENT_LABEL}"

⚠️ 바로 코드를 작성하지 마세요. 반드시 사용자에게 먼저 확인하세요:
1. 요청의 복잡도를 판단한다.
2. AskUserQuestion 도구로 사용자에게 물어본다:
   - "새로운 작업으로 보입니다. 어떻게 진행할까요?"
   - 선택지: "바로 진행", "/plan-manager로 계획 수립"
3. 사용자의 선택에 따라 진행한다.
MSG
  else
    cat <<MSG
[시스템 지시] 진행 중인 계획이 없습니다.
감지된 의도: "${INTENT_LABEL}"

⚠️ 바로 코드를 작성하지 마세요. 반드시 사용자에게 먼저 확인하세요:
1. 요청의 복잡도를 판단한다.
2. AskUserQuestion 도구로 사용자에게 물어본다:
   - 간단한 작업이면: "간단한 작업으로 보입니다. 바로 진행할까요?"
   - 복잡한 작업이면: "복잡한 작업으로 보입니다. /plan-manager로 계획을 먼저 수립할까요?"
   - 선택지: "바로 진행", "/plan-manager로 계획 수립"
3. 사용자의 선택에 따라 진행한다.
MSG
  fi
fi

exit 0
