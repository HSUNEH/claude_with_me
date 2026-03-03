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

# 매칭 유틸리티 로드
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/matcher.sh"

LOG_FILE="$CWD/docs/logs/change-log.md"

# 변경 로그가 없으면 스킵
if [ ! -f "$LOG_FILE" ]; then
  exit 0
fi

# ── 0. 같은 턴 계획+구현 위반 감지 (CHANGED_FILES 추출 전에 실행) ──
RECENT_LOG=$(tail -30 "$LOG_FILE")
HAS_PLAN_WRITE=false
HAS_CODE_CHANGE=false
PLAN_TS=""
CODE_TS=""

# 계획 문서 Write/Edit 감지 (docs/plans/ 하위의 PLAN.md, CONTEXT.md, CHECKLIST.md)
PLAN_LINE=$(echo "$RECENT_LOG" | grep -E '\| (Write|Edit) \|' | grep -E '/(PLAN|CONTEXT|CHECKLIST)\.md' | grep -E '/docs/plans/' | tail -1)
if [ -n "$PLAN_LINE" ]; then
  HAS_PLAN_WRITE=true
  PLAN_TS=$(echo "$PLAN_LINE" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' | head -1)
fi

# 비문서 코드 파일 Edit/Write 감지 (docs/, plans/, logs/, reports/ 제외)
CODE_LINE=$(echo "$RECENT_LOG" | grep -E '\| (Edit|Write) \|' | grep -vE '/(docs/|plans/|logs/|reports/)' | grep -vE '/(CHECKLIST|PLAN|CONTEXT|CLAUDE)\.md' | tail -1)
if [ -n "$CODE_LINE" ]; then
  HAS_CODE_CHANGE=true
  CODE_TS=$(echo "$CODE_LINE" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' | head -1)
fi

SAME_TURN_VIOLATION=false
if $HAS_PLAN_WRITE && $HAS_CODE_CHANGE && [ -n "$PLAN_TS" ] && [ -n "$CODE_TS" ]; then
  # macOS/Linux 호환 epoch 변환
  if date -j &>/dev/null 2>&1; then
    # macOS
    PLAN_EPOCH=$(date -j -f "%Y-%m-%d %H:%M:%S" "$PLAN_TS" +%s 2>/dev/null || echo 0)
    CODE_EPOCH=$(date -j -f "%Y-%m-%d %H:%M:%S" "$CODE_TS" +%s 2>/dev/null || echo 0)
  else
    # Linux
    PLAN_EPOCH=$(date -d "$PLAN_TS" +%s 2>/dev/null || echo 0)
    CODE_EPOCH=$(date -d "$CODE_TS" +%s 2>/dev/null || echo 0)
  fi

  if [ "$PLAN_EPOCH" -gt 0 ] && [ "$CODE_EPOCH" -gt 0 ]; then
    DIFF=$(( CODE_EPOCH - PLAN_EPOCH ))
    [ $DIFF -lt 0 ] && DIFF=$(( -DIFF ))
    if [ $DIFF -le 600 ]; then
      SAME_TURN_VIOLATION=true
    fi
  fi
fi

if $SAME_TURN_VIOLATION; then
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
fi

# 최근 변경된 파일 목록 추출 (macOS 호환: -oE 사용)
CHANGED_FILES=$(tail -20 "$LOG_FILE" | grep -oE '`[^`]+\.[a-z]+`' | tr -d '`' | sort -u)

if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

# ── 검사 결과 수집 ──
ERRORS=""
ERROR_COUNT=0
PATTERN_WARNINGS=""
PATTERN_COUNT=0

# ── A. 린트/타입 자동 검사 (기존) ──

# TypeScript/JavaScript
if command -v npx &>/dev/null; then
  if [ -f "$CWD/node_modules/.bin/eslint" ] || ls "$CWD"/.eslintrc* "$CWD"/eslint.config* 2>/dev/null | head -1 >/dev/null 2>&1; then
    for f in $CHANGED_FILES; do
      if [[ "$f" == *.ts || "$f" == *.tsx || "$f" == *.js || "$f" == *.jsx ]]; then
        TARGET="$f"
        [ ! -f "$TARGET" ] && TARGET="$CWD/$f"
        if [ -f "$TARGET" ]; then
          LINT_RESULT=$(cd "$CWD" && npx eslint "$TARGET" --no-color 2>&1 | tail -5)
          if [ -n "$LINT_RESULT" ] && echo "$LINT_RESULT" | grep -qiE "(error|warning)"; then
            ERRORS="${ERRORS}\n[ESLint] ${f}:\n${LINT_RESULT}\n"
            ERROR_COUNT=$((ERROR_COUNT + 1))
          fi
        fi
      fi
    done
  fi

  if [ -f "$CWD/tsconfig.json" ]; then
    TSC_RESULT=$(cd "$CWD" && npx tsc --noEmit 2>&1 | tail -10)
    if echo "$TSC_RESULT" | grep -qiE "error TS"; then
      TSC_COUNT=$(echo "$TSC_RESULT" | grep -c "error TS")
      ERRORS="${ERRORS}\n[TypeScript] 타입 에러 ${TSC_COUNT}건:\n${TSC_RESULT}\n"
      ERROR_COUNT=$((ERROR_COUNT + TSC_COUNT))
    fi
  fi
fi

# Python
if command -v python3 &>/dev/null; then
  for f in $CHANGED_FILES; do
    if [[ "$f" == *.py ]]; then
      TARGET="$f"
      [ ! -f "$TARGET" ] && TARGET="$CWD/$f"
      if [ -f "$TARGET" ]; then
        PY_RESULT=$(python3 -m py_compile "$TARGET" 2>&1)
        if [ $? -ne 0 ]; then
          ERRORS="${ERRORS}\n[Python] ${f}:\n${PY_RESULT}\n"
          ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
      fi
    fi
  done
fi

# ── B. 코드 패턴 검사 (신규: 매칭 조건 4) ──
for f in $CHANGED_FILES; do
  TARGET="$f"
  [ ! -f "$TARGET" ] && TARGET="$CWD/$f"

  if [ -f "$TARGET" ]; then
    # 4. 파일 내용 패턴 감지
    PATTERNS=$(detect_code_patterns "$TARGET")
    if [ -n "$PATTERNS" ]; then
      # 3. 작업 위치 감지
      LOCATION=$(detect_location "$f")
      FOCUS=$(location_to_focus "$LOCATION")
      PATTERN_WARNINGS="${PATTERN_WARNINGS}\n📄 ${f} (${LOCATION}):\n${PATTERNS}   중점: ${FOCUS}\n"
      PATTERN_COUNT=$((PATTERN_COUNT + 1))
    fi
  fi
done

# ── 결과 종합 출력 ──
TOTAL_ISSUES=$((ERROR_COUNT + PATTERN_COUNT))

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

exit 0
