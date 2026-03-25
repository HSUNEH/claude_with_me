#!/bin/bash
# ============================================================
# [PreToolUse Hook] CWM Plan Enforcer
# ============================================================
# Layer 3: 안전망. 활성 플랜 없이 N개+ 파일 수정 시 차단.
#
# 동작:
#   - 활성 플랜(.status=active) 있으면 → 무조건 통과
#   - 없으면 → 수정 파일 수 카운트
#   - 임계값 초과 시 → exit 2 (차단)
#   - docs/, .cwm/, .claude/ 내 파일은 카운트 제외
# ============================================================

INPUT=$(cat)

# 안전 장치: jq 없으면 통과
command -v jq &>/dev/null || exit 0

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Edit/Write 외 도구는 통과
[[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]] && exit 0

# ── 설정 ──
PLANS_DIR="$CWD/docs/plans"
STATE_DIR="$CWD/.cwm/state"
TRACKER_FILE="$STATE_DIR/edit-tracker"
THRESHOLD=3  # config.yml에서 읽기 가능하도록 확장 예정

# config.yml에서 threshold 읽기 시도
CONFIG_FILE="$CWD/.cwm/config.yml"
if [ -f "$CONFIG_FILE" ]; then
  _T=$(grep -A1 'plan_enforcer:' "$CONFIG_FILE" 2>/dev/null | grep 'threshold:' | grep -oE '[0-9]+' | head -1)
  [ -n "$_T" ] && THRESHOLD="$_T"
fi

# ── 활성 플랜 확인 (.status 파일 기반) ──
if [ -d "$PLANS_DIR" ]; then
  for status_file in "$PLANS_DIR"/*/.status; do
    [ -f "$status_file" ] || continue
    if grep -qx "active" "$status_file" 2>/dev/null; then
      # 활성 플랜 있음 → 무조건 통과
      exit 0
    fi
  done
fi

# ── 비코드 파일은 카운트 제외 ──
case "$FILE_PATH" in
  */docs/*|*/.cwm/*|*/.claude/*|*/CLAUDE.md|*/.status|*/change-log.md)
    exit 0
    ;;
esac

# ── 수정 파일 카운트 ──
mkdir -p "$STATE_DIR"

# 트래커 파일이 30분 이상 오래되었으면 리셋
if [ -f "$TRACKER_FILE" ]; then
  if command -v stat &>/dev/null; then
    FILE_AGE=0
    if stat -f %m "$TRACKER_FILE" &>/dev/null 2>&1; then
      # macOS
      FILE_MOD=$(stat -f %m "$TRACKER_FILE")
      NOW=$(date +%s)
      FILE_AGE=$(( NOW - FILE_MOD ))
    elif stat -c %Y "$TRACKER_FILE" &>/dev/null 2>&1; then
      # Linux
      FILE_MOD=$(stat -c %Y "$TRACKER_FILE")
      NOW=$(date +%s)
      FILE_AGE=$(( NOW - FILE_MOD ))
    fi
    [ "$FILE_AGE" -gt 1800 ] && rm -f "$TRACKER_FILE"
  fi
fi

# 현재 파일이 이미 추적 중인지 확인
if [ -f "$TRACKER_FILE" ] && grep -qxF "$FILE_PATH" "$TRACKER_FILE" 2>/dev/null; then
  # 이미 추적 중 → 통과 (같은 파일 재수정)
  exit 0
fi

# 새 파일 추가
echo "$FILE_PATH" >> "$TRACKER_FILE"

# 파일 수 확인
FILE_COUNT=$(wc -l < "$TRACKER_FILE" | tr -d ' ')

if [ "$FILE_COUNT" -ge "$THRESHOLD" ]; then
  cat >&2 <<MSG
───────────────────────────────────────────
⛔ [CWM] 플랜 없이 ${FILE_COUNT}개 파일을 수정하려 합니다
───────────────────────────────────────────

여러 파일을 수정하는 큰 작업으로 보입니다.

  /cwm:planwithme {작업명}  → 플랜을 먼저 세우세요
  "간단: {요청}"            → 플랜 없이 계속 진행

───────────────────────────────────────────
MSG
  exit 2
fi

# 임계값 미만 → 통과
exit 0
