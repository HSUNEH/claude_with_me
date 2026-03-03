#!/bin/bash
# ============================================================
# [Stop Hook] 완료 후 검사 장치 — 린트 & 타입 & 코드 패턴
# ============================================================
# 매칭 조건 활용:
#   3. 작업 위치 → 변경 파일 위치별 검사 전략 분기
#   4. 파일 내용 → 린트 외에 코드 패턴 직접 검사 추가
# ============================================================

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/matcher.sh"

LOG_FILE="$CWD/docs/logs/change-log.md"

# ── 함수 정의 ──

_check_same_turn_violation() {
  local RECENT_LOG=$(tail -30 "$LOG_FILE")

  local PLAN_LINE=$(echo "$RECENT_LOG" | grep -E '\| (Write|Edit) \|' | grep -E '/(PLAN|CONTEXT|CHECKLIST)\.md' | grep -E '/docs/plans/' | tail -1)
  [ -z "$PLAN_LINE" ] && return 1

  local CODE_LINE=$(echo "$RECENT_LOG" | grep -E '\| (Edit|Write) \|' | grep -vE '/(docs/|plans/|logs/|reports/)' | grep -vE '/(CHECKLIST|PLAN|CONTEXT|CLAUDE)\.md' | tail -1)
  [ -z "$CODE_LINE" ] && return 1

  local PLAN_TS=$(echo "$PLAN_LINE" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' | head -1)
  local CODE_TS=$(echo "$CODE_LINE" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' | head -1)
  [ -z "$PLAN_TS" ] || [ -z "$CODE_TS" ] && return 1

  local PLAN_EPOCH CODE_EPOCH
  if date -j &>/dev/null 2>&1; then
    PLAN_EPOCH=$(date -j -f "%Y-%m-%d %H:%M:%S" "$PLAN_TS" +%s 2>/dev/null || echo 0)
    CODE_EPOCH=$(date -j -f "%Y-%m-%d %H:%M:%S" "$CODE_TS" +%s 2>/dev/null || echo 0)
  else
    PLAN_EPOCH=$(date -d "$PLAN_TS" +%s 2>/dev/null || echo 0)
    CODE_EPOCH=$(date -d "$CODE_TS" +%s 2>/dev/null || echo 0)
  fi

  [ "$PLAN_EPOCH" -le 0 ] || [ "$CODE_EPOCH" -le 0 ] && return 1

  local DIFF=$(( CODE_EPOCH - PLAN_EPOCH ))
  [ $DIFF -lt 0 ] && DIFF=$(( -DIFF ))
  [ $DIFF -gt 600 ] && return 1

  cat <<'VIOLATION'
───────────────────────────────────────────
🚨 [워크플로우 위반] 같은 턴에서 계획 수립과 코드 구현이 감지되었습니다
───────────────────────────────────────────

계획 문서 생성과 코드 파일 수정이 동일 턴에 발생했습니다.

정상 절차: 계획 승인 → /clear → 구현 시작
실제 발생: 계획 승인 → 바로 구현 (⚠️ /clear 생략)

→ 다음부터 계획 승인 후 반드시 /clear를 거쳐 컨텍스트를 정리하세요.
───────────────────────────────────────────
VIOLATION
}

_run_lint_checks() {
  # TypeScript/JavaScript
  if command -v npx &>/dev/null; then
    if [ -f "$CWD/node_modules/.bin/eslint" ] || ls "$CWD"/.eslintrc* "$CWD"/eslint.config* 2>/dev/null | head -1 >/dev/null 2>&1; then
      for f in $CHANGED_FILES; do
        if [[ "$f" == *.ts || "$f" == *.tsx || "$f" == *.js || "$f" == *.jsx ]]; then
          local TARGET="$f"
          [ ! -f "$TARGET" ] && TARGET="$CWD/$f"
          if [ -f "$TARGET" ]; then
            local LINT_RESULT=$(cd "$CWD" && npx eslint "$TARGET" --no-color 2>&1 | tail -5)
            if [ -n "$LINT_RESULT" ] && echo "$LINT_RESULT" | grep -qiE "(error|warning)"; then
              ERRORS="${ERRORS}\n[ESLint] ${f}:\n${LINT_RESULT}\n"
              ERROR_COUNT=$((ERROR_COUNT + 1))
            fi
          fi
        fi
      done
    fi

    if [ -f "$CWD/tsconfig.json" ]; then
      local TSC_RESULT=$(cd "$CWD" && npx tsc --noEmit 2>&1 | tail -10)
      if echo "$TSC_RESULT" | grep -qiE "error TS"; then
        local TSC_COUNT=$(echo "$TSC_RESULT" | grep -c "error TS")
        ERRORS="${ERRORS}\n[TypeScript] 타입 에러 ${TSC_COUNT}건:\n${TSC_RESULT}\n"
        ERROR_COUNT=$((ERROR_COUNT + TSC_COUNT))
      fi
    fi
  fi

  # Python
  if command -v python3 &>/dev/null; then
    for f in $CHANGED_FILES; do
      if [[ "$f" == *.py ]]; then
        local TARGET="$f"
        [ ! -f "$TARGET" ] && TARGET="$CWD/$f"
        if [ -f "$TARGET" ]; then
          local PY_RESULT=$(python3 -m py_compile "$TARGET" 2>&1)
          if [ $? -ne 0 ]; then
            ERRORS="${ERRORS}\n[Python] ${f}:\n${PY_RESULT}\n"
            ERROR_COUNT=$((ERROR_COUNT + 1))
          fi
        fi
      fi
    done
  fi

  # 코드 패턴 검사
  for f in $CHANGED_FILES; do
    local TARGET="$f"
    [ ! -f "$TARGET" ] && TARGET="$CWD/$f"
    if [ -f "$TARGET" ]; then
      local PATTERNS=$(detect_code_patterns "$TARGET")
      if [ -n "$PATTERNS" ]; then
        local LOCATION=$(detect_location "$f")
        local FOCUS=$(location_to_focus "$LOCATION")
        PATTERN_WARNINGS="${PATTERN_WARNINGS}\n📄 ${f} (${LOCATION}):\n${PATTERNS}   중점: ${FOCUS}\n"
        PATTERN_COUNT=$((PATTERN_COUNT + 1))
      fi
    fi
  done
}

_print_results() {
  local TOTAL_ISSUES=$((ERROR_COUNT + PATTERN_COUNT))

  if [ $TOTAL_ISSUES -eq 0 ]; then
    cat <<'PASS'
───────────────────────────────────────────
✅ [완료 후 검사] 모든 검사 통과
───────────────────────────────────────────
린트/타입 체크 통과, 코드 패턴 경고 없음.

최종 셀프체크:
□ 에러 처리는 빠짐없이 추가했는가?
□ 보안상 위험한 부분은 없는가?
□ 엣지 케이스를 놓치지 않았는가?
□ 요청 범위를 벗어난 변경은 없는가?
□ 더 단순하게 할 수 있는가?
───────────────────────────────────────────
PASS

  elif [ $TOTAL_ISSUES -le 3 ]; then
    cat <<MSG
───────────────────────────────────────────
⚠️ [완료 후 검사] 이슈 ${TOTAL_ISSUES}건 — 즉시 수정
───────────────────────────────────────────
MSG
    [ $ERROR_COUNT -gt 0 ] && echo -e "\n🔴 린트/타입 오류 ${ERROR_COUNT}건:${ERRORS}"
    [ $PATTERN_COUNT -gt 0 ] && echo -e "\n🟡 코드 패턴 경고 ${PATTERN_COUNT}건:${PATTERN_WARNINGS}"
    cat <<'MSG'

오류가 적으므로 직접 수정하세요.
수정 후 다시 검사가 실행됩니다.
───────────────────────────────────────────
MSG

  else
    cat <<MSG
───────────────────────────────────────────
🚨 [완료 후 검사] 이슈 ${TOTAL_ISSUES}건 — 전문 에이전트 권장
───────────────────────────────────────────
MSG
    [ $ERROR_COUNT -gt 0 ] && echo -e "\n🔴 린트/타입 오류 ${ERROR_COUNT}건:${ERRORS}"
    [ $PATTERN_COUNT -gt 0 ] && echo -e "\n🟡 코드 패턴 경고 ${PATTERN_COUNT}건:${PATTERN_WARNINGS}"
    cat <<'MSG'

오류가 많습니다. 전문 서브에이전트 호출을 권장합니다:

  qa-agent       → 코드 검토 & 오류 수정 & 구조 개선
  test-agent     → 기능 테스트 & 오류 진단
  planning-agent → 계획 재검토 & 문서 작성

서브에이전트가 자동 위임되어 보고서를 작성합니다.
───────────────────────────────────────────
MSG
  fi
}

# ── main ──

[ ! -f "$LOG_FILE" ] && exit 0

_check_same_turn_violation

CHANGED_FILES=$(tail -20 "$LOG_FILE" | grep -oE '`[^`]+\.[a-z]+`' | tr -d '`' | sort -u)
[ -z "$CHANGED_FILES" ] && exit 0

ERRORS=""
ERROR_COUNT=0
PATTERN_WARNINGS=""
PATTERN_COUNT=0

_run_lint_checks
_print_results

exit 0
