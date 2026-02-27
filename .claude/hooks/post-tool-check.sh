#!/bin/bash
# ============================================================
# [PostToolUse Hook] 도구 사용 후 품질 셀프체크
# ============================================================
# 매칭 조건 활용:
#   3. 작업 위치 → 파일 경로에서 도메인 감지 → 맞춤형 체크 항목
#   4. 파일 내용 → 코드 패턴 감지 → 구체적 문제 지적
# ============================================================

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# 매칭 유틸리티 로드
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/matcher.sh"

# ── Edit / Write 도구 ──
if [[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

  # ── 0. 계획 없는 코드 변경 감지
  # docs/, .claude/ 등 비코드 파일은 제외
  _IS_CODE_FILE=true
  case "$FILE_PATH" in
    */docs/*|*/plans/*|*/logs/*|*/reports/*|*CHECKLIST*|*PLAN.md|*CONTEXT.md|*CLAUDE.md|*.md)
      _IS_CODE_FILE=false
      ;;
  esac

  if $_IS_CODE_FILE; then
    PLANS_DIR="$CWD/docs/plans"
    if [ -d "$PLANS_DIR" ]; then
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
        cat <<'WARN'
───────────────────────────────────────────
⚠️ [무계획 변경 감지] 활성 계획 없이 코드가 변경되었습니다
───────────────────────────────────────────

모든 계획이 🟢 완료 상태인데 코드 파일이 수정되었습니다.

→ 추가 변경을 계속하기 전에 AskUserQuestion으로 사용자에게 확인하세요.
→ 필요하다면 /plan-manager로 새 계획을 수립하세요.
───────────────────────────────────────────
WARN
      fi
    fi
  fi

  # 3. 작업 위치 감지 → 맞춤형 검사 중점
  LOCATION=$(detect_location "$FILE_PATH")
  FOCUS=$(location_to_focus "$LOCATION")

  # 위치별 한글 라벨 (config.yml에서 읽기)
  LOC_LABEL=$(location_to_label "$LOCATION")

  # 4. 파일 내용 패턴 감지 → 구체적 문제 지적
  FULL_PATH="$FILE_PATH"
  [ ! -f "$FULL_PATH" ] && FULL_PATH="$CWD/$FILE_PATH"

  CODE_ISSUES=""
  if [ -f "$FULL_PATH" ]; then
    CODE_ISSUES=$(detect_code_patterns "$FULL_PATH")
  fi

  # ── 출력: 맞춤형 셀프체크
  cat <<MSG
───────────────────────────────────────────
🔍 [품질 검사] ${FILE_PATH}
   레이어: ${LOC_LABEL} | 중점: ${FOCUS}
───────────────────────────────────────────
MSG

  # 코드 패턴에서 문제가 감지되면 구체적으로 표시
  if [ -n "$CODE_ISSUES" ]; then
    cat <<MSG

🚩 코드 패턴 감지:
$(echo -e "$CODE_ISSUES" | sed 's/^/   /')
MSG
  fi

  # 위치별 맞춤 체크리스트 (config.yml에서 읽기)
  echo ""
  location_to_checklist "$LOCATION"

  echo "───────────────────────────────────────────"

# ── Bash 도구 ──
elif [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  # 1. 키워드 매칭: 위험 명령어 감지
  if echo "$COMMAND" | grep -qiE '(rm -rf|drop |truncate |--force|reset --hard)'; then
    cat <<WARN
───────────────────────────────────────────
⚠️ [안전 경고] 위험 명령어 실행 감지
───────────────────────────────────────────
실행된 명령: ${COMMAND}

결과를 반드시 확인하고, 의도한 대로 동작했는지 검증하세요.
───────────────────────────────────────────
WARN
  fi
fi

exit 0
