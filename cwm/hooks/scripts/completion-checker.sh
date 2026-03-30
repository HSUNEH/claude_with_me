#!/bin/bash
# ============================================================
# [Stop Hook] CWM Completion Checker
# ============================================================
# 작업 완료 시 린트/타입 검사 수행.
# 에러 0건=통과, 1-3건=즉시수정, 4건+=qa-agent 위임 권장.
# ============================================================

INPUT=$(cat)

command -v jq &>/dev/null || exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
CWD=$(cd "$CWD" 2>/dev/null && pwd) || exit 0

# ── 프로젝트 루트 찾기 (CWD에서 상위로 .cwm/.initialized 탐색) ──
PROJECT_ROOT="$CWD"
while [ "$PROJECT_ROOT" != "/" ]; do
  [ -f "$PROJECT_ROOT/.cwm/.initialized" ] && break
  PROJECT_ROOT=$(dirname "$PROJECT_ROOT")
done
[ -f "$PROJECT_ROOT/.cwm/.initialized" ] || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/matcher.sh" ]; then
  source "$SCRIPT_DIR/lib/matcher.sh" 2>/dev/null
fi

LOG_FILE="$PROJECT_ROOT/.cwm/docs/logs/change-log.md"
[ ! -f "$LOG_FILE" ] && exit 0

# ── 변경 파일 추출 ──
CHANGED_FILES=$(tail -20 "$LOG_FILE" | grep -oE '`[^`]+\.[a-z]+`' | tr -d '`' | sort -u)
[ -z "$CHANGED_FILES" ] && exit 0

ERRORS=""
ERROR_COUNT=0
PATTERN_WARNINGS=""
PATTERN_COUNT=0

# ── 린트 검사 ──

# TypeScript / JavaScript
if command -v npx &>/dev/null; then
  if [ -f "$CWD/node_modules/.bin/eslint" ] || ls "$CWD"/.eslintrc* "$CWD"/eslint.config* 2>/dev/null | head -1 >/dev/null 2>&1; then
    for f in $CHANGED_FILES; do
      if [[ "$f" == *.ts || "$f" == *.tsx || "$f" == *.js || "$f" == *.jsx ]]; then
        TARGET="$f"
        [ ! -f "$TARGET" ] && TARGET="$PROJECT_ROOT/$f"
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
      ERRORS="${ERRORS}\n[TypeScript] ${TSC_COUNT} type errors:\n${TSC_RESULT}\n"
      ERROR_COUNT=$((ERROR_COUNT + TSC_COUNT))
    fi
  fi
fi

# Python
if command -v python3 &>/dev/null; then
  for f in $CHANGED_FILES; do
    if [[ "$f" == *.py ]]; then
      TARGET="$f"
      [ ! -f "$TARGET" ] && TARGET="$PROJECT_ROOT/$f"
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

# ── 코드 패턴 검사 ──
for f in $CHANGED_FILES; do
  TARGET="$f"
  [ ! -f "$TARGET" ] && TARGET="$PROJECT_ROOT/$f"
  if [ -f "$TARGET" ]; then
    # 보안 위험 함수
    SEC=$(grep -nE '(eval\(|innerHTML|dangerouslySetInnerHTML|exec\()' "$TARGET" 2>/dev/null | head -3)
    if [ -n "$SEC" ]; then
      PATTERN_WARNINGS="${PATTERN_WARNINGS}\n[Security] ${f}:\n${SEC}\n"
      PATTERN_COUNT=$((PATTERN_COUNT + 1))
    fi
    # 하드코딩 비밀정보
    SECRET=$(grep -nE '(password|secret|api_key|token)\s*[:=]\s*[\"'"'"'][^\"'"'"']' "$TARGET" 2>/dev/null | head -3)
    if [ -n "$SECRET" ]; then
      PATTERN_WARNINGS="${PATTERN_WARNINGS}\n[Security] Hardcoded secret in ${f}:\n${SECRET}\n"
      PATTERN_COUNT=$((PATTERN_COUNT + 1))
    fi
  fi
done

# ── 결과 출력 ──
TOTAL_ISSUES=$((ERROR_COUNT + PATTERN_COUNT))

if [ $TOTAL_ISSUES -eq 0 ]; then
  # 깔끔 → 플랜 상태 업데이트 안내만
  PLANS_DIR="$PROJECT_ROOT/.cwm/docs/plans"
  if [ -d "$PLANS_DIR" ]; then
    for status_file in "$PLANS_DIR"/*/.status; do
      [ -f "$status_file" ] || continue
      if grep -qx "active" "$status_file" 2>/dev/null; then
        PLAN_NAME=$(basename "$(dirname "$status_file")")
        echo "CWM: All checks passed. Active plan: ${PLAN_NAME}"
        exit 0
      fi
    done
  fi
  # 활성 플랜 없으면 조용히 통과
  exit 0

elif [ $TOTAL_ISSUES -le 3 ]; then
  cat <<MSG
───────────────────────────────────────────
⚠️ [CWM] ${TOTAL_ISSUES} issues found — fix directly
───────────────────────────────────────────
MSG
  [ $ERROR_COUNT -gt 0 ] && echo -e "\nLint/Type errors (${ERROR_COUNT}):${ERRORS}"
  [ $PATTERN_COUNT -gt 0 ] && echo -e "\nCode pattern warnings (${PATTERN_COUNT}):${PATTERN_WARNINGS}"
  echo "───────────────────────────────────────────"

else
  cat <<MSG
───────────────────────────────────────────
🚨 [CWM] ${TOTAL_ISSUES} issues found — consider qa-agent
───────────────────────────────────────────
MSG
  [ $ERROR_COUNT -gt 0 ] && echo -e "\nLint/Type errors (${ERROR_COUNT}):${ERRORS}"
  [ $PATTERN_COUNT -gt 0 ] && echo -e "\nCode pattern warnings (${PATTERN_COUNT}):${PATTERN_WARNINGS}"
  cat <<'MSG'

Recommended: delegate to qa-agent for review & auto-fix.
───────────────────────────────────────────
MSG
fi

exit 0
