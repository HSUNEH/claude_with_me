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

# 매칭 유틸리티 로드
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/matcher.sh"

# ── 0. 초기 세팅 완료 확인 (스킬 바이패스보다 먼저 체크)
INIT_MARKER="$CWD/.claude/.initialized"
SETUP_IN_PROGRESS="$CWD/.claude/.setup-in-progress"
if [ ! -f "$INIT_MARKER" ]; then
  # /setup 진행 중이면 통과
  if [ -f "$SETUP_IN_PROGRESS" ]; then
    exit 0
  fi
  # .claude/ 디렉토리가 존재하는데 .initialized가 없으면 = 세팅 미완료
  if [ -d "$CWD/.claude/hooks" ]; then
    # /setup 명령만 허용, 나머지는 모두 차단
    if echo "$PROMPT" | grep -qE '^\s*/setup(\s|$)'; then
      exit 0
    fi
    cat >&2 <<'MSG'
───────────────────────────────────────────
⛔ [세팅 미완료] /setup이 아직 완료되지 않았습니다
───────────────────────────────────────────

👉 /setup 을 실행하여 세팅을 완료하세요.

💡 GitHub에서 설치한 직후라면:
   Claude Code를 한번 종료(/exit)한 뒤 다시 시작하세요.
   재시작해야 /setup 스킬이 인식됩니다.
───────────────────────────────────────────
MSG
    exit 2
  fi
fi

# ── 0.5. 스킬 커맨드 바이패스 (/plan-manager, /dev-manual 등)
# setup 완료 후에는 슬래시로 시작하는 스킬 명령을 통과시킨다.
if echo "$PROMPT" | grep -qE '^\s*/[a-zA-Z]'; then
  exit 0
fi

# ── 1. 글로벌 계획 강제 토글 확인
if $_HAS_CONFIG 2>/dev/null; then
  GLOBAL_REQUIRE=$(cfg_get_general "require_plan" 2>/dev/null)
  if [ "$GLOBAL_REQUIRE" = "false" ]; then
    exit 0
  fi
fi

# ── 2. 키워드 매칭
KEYWORD_TYPE=$(match_keywords "$PROMPT")
if [ "$KEYWORD_TYPE" = "none" ]; then
  exit 0
fi

# ── 3. 의도 파악
INTENT=$(detect_intent "$PROMPT")

# config.yml의 require_plan 설정에 따라 계획 강제 여부 판별
if ! intent_requires_plan "$INTENT"; then
  # 계획 없어도 진행 가능 — 가벼운 안내만
  PLANS_DIR="$CWD/docs/plans"
  if [ -d "$PLANS_DIR" ]; then
    IN_PROGRESS=""
    for checklist in "$PLANS_DIR"/*/CHECKLIST.md; do
      [ -f "$checklist" ] || continue
      if grep -q "🟡 진행 중" "$checklist" 2>/dev/null; then
        PLAN_NAME=$(basename "$(dirname "$checklist")")
        IN_PROGRESS="$PLAN_NAME"
        break
      fi
    done
    if [ -n "$IN_PROGRESS" ]; then
      echo "───────────────────────────────────────────"
      echo "📋 참고: 진행 중인 작업 '${IN_PROGRESS}'이 있습니다."
      echo "───────────────────────────────────────────"
    fi
  fi
  exit 0
fi

PLANS_DIR="$CWD/docs/plans"

# ── 4. 작업 위치: 프롬프트에 파일 경로가 언급되었으면 관련 계획 탐색
FILE_MENTION=$(echo "$PROMPT" | grep -oE '[a-zA-Z0-9_/.-]+\.(ts|tsx|js|jsx|py|vue|svelte|css|json)' | head -1)
RELATED_PLAN=""
if [ -n "$FILE_MENTION" ] && [ -d "$PLANS_DIR" ]; then
  for plan in "$PLANS_DIR"/*/PLAN.md; do
    [ -f "$plan" ] || continue
    if grep -q "$FILE_MENTION" "$plan" 2>/dev/null; then
      RELATED_PLAN=$(basename "$(dirname "$plan")")
      break
    fi
  done
fi

# plans 디렉토리 존재 확인
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

# 파일 경로로 관련 계획을 찾은 경우
if [ -n "$RELATED_PLAN" ]; then
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

# 체크리스트 상태별 분류
IN_PROGRESS=""
PENDING_APPROVAL=""
ALL_COMPLETED=true
for checklist in "$PLANS_DIR"/*/CHECKLIST.md; do
  [ -f "$checklist" ] || continue
  if grep -q "🟡 진행 중" "$checklist" 2>/dev/null; then
    PLAN_DIR=$(dirname "$checklist")
    PLAN_NAME=$(basename "$PLAN_DIR")
    IN_PROGRESS="$PLAN_NAME"
    ALL_COMPLETED=false
    break
  elif grep -q "🔴 시작 전" "$checklist" 2>/dev/null; then
    PLAN_DIR=$(dirname "$checklist")
    PLAN_NAME=$(basename "$PLAN_DIR")
    PENDING_APPROVAL="$PLAN_NAME"
    ALL_COMPLETED=false
  elif grep -q "🟢 완료" "$checklist" 2>/dev/null; then
    : # 완료 상태 — ALL_COMPLETED 유지
  else
    ALL_COMPLETED=false
  fi
done

# ── 미승인 계획 감지 (🔴 시작 전) — 안내
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
  PLAN_DIR="$PLANS_DIR/$IN_PROGRESS"
  CHECKLIST_FILE="$PLAN_DIR/CHECKLIST.md"

  # CHECKLIST.md에서 진행 상황 추출
  TOTAL_TASKS=0
  DONE_TASKS=0
  CURRENT_PHASE=""
  NEXT_ITEMS=""

  if [ -f "$CHECKLIST_FILE" ]; then
    TOTAL_TASKS=$(grep -c '^\s*- \[' "$CHECKLIST_FILE" 2>/dev/null || echo "0")
    DONE_TASKS=$(grep -c '^\s*- \[x\]' "$CHECKLIST_FILE" 2>/dev/null || echo "0")

    # 현재 Phase: 첫 번째 미체크 Phase 라인
    CURRENT_PHASE=$(grep -m1 '^\s*- \[ \] Phase' "$CHECKLIST_FILE" 2>/dev/null | sed 's/^.*- \[ \] //')

    # 현재 Phase의 세부 작업 (미체크 항목만, 최대 5개)
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

  if [ -n "$CURRENT_PHASE" ]; then
    echo "현재: ${CURRENT_PHASE}"
  fi
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
else
  # ── 활성 계획 없음: 항상 사용자에게 확인 후 진행
  DETECTED_INTENT=$(detect_intent "$PROMPT")
  INTENT_LABEL=$(intent_to_label "$DETECTED_INTENT")
  cat <<MSG
[시스템 지시] 진행 중인 계획이 없습니다.
사용자가 "${INTENT_LABEL}" 작업을 요청했습니다.

바로 코드를 작성하지 마세요. 반드시 사용자에게 먼저 확인하세요:
1. 요청의 복잡도를 판단한다.
2. 사용자에게 다음과 같이 물어본다:
   - 간단한 작업이면: "간단한 작업으로 보입니다. 바로 진행할까요, 아니면 /plan-manager로 계획을 수립할까요?"
   - 복잡한 작업이면: "복잡한 작업으로 보입니다. /plan-manager로 계획을 먼저 수립하겠습니다. 진행할까요?"
3. 사용자가 응답할 때까지 기다린다.
4. 사용자의 선택에 따라 진행한다.
MSG
  exit 0
fi

exit 0
