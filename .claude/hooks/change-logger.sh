#!/bin/bash
# ============================================================
# [PostToolUse Hook] 수정 기록 장치 — 변경 로그 자동 저장
# ============================================================
# 역할: Edit/Write/Bash 도구 사용 후 변경 내역을
#       docs/logs/change-log.md 에 자동 누적 기록한다.
#
# 기록 항목: 시간, 도구, 파일경로, 작업 요약
# ============================================================

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

LOG_DIR="$CWD/docs/logs"
LOG_FILE="$LOG_DIR/change-log.md"

# 로그 디렉토리 없으면 생성
mkdir -p "$LOG_DIR"

# 로그 파일 초기화 (없으면)
if [ ! -f "$LOG_FILE" ]; then
  cat > "$LOG_FILE" <<'HEADER'
# 변경 로그

> 자동 생성 파일 — Hook(change-logger.sh)이 매 파일 변경 시 기록합니다.

| 시간 | 도구 | 파일 | 작업 |
|------|------|------|------|
HEADER
fi

# --- Edit 도구 ---
if [ "$TOOL_NAME" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // "unknown"')
  OLD_STR=$(echo "$INPUT" | jq -r '.tool_input.old_string // ""' | head -c 60)
  echo "| $TIMESTAMP | Edit | \`$FILE_PATH\` | \`${OLD_STR}...\` → 수정 |" >> "$LOG_FILE"

# --- Write 도구 ---
elif [ "$TOOL_NAME" = "Write" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // "unknown"')
  echo "| $TIMESTAMP | Write | \`$FILE_PATH\` | 파일 생성/덮어쓰기 |" >> "$LOG_FILE"

# --- Bash 도구 (파일 조작 명령만) ---
elif [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

  # 파일 변경 관련 명령만 기록 (mv, cp, rm, mkdir, chmod, npm install 등)
  if echo "$COMMAND" | grep -qE '(mv |cp |rm |mkdir |chmod |npm install|pnpm |yarn |pip )'; then
    CMD_SHORT=$(echo "$COMMAND" | head -c 80)
    echo "| $TIMESTAMP | Bash | — | \`${CMD_SHORT}\` |" >> "$LOG_FILE"
  fi
fi

# stdout 없음 — 로깅만 수행 (컨텍스트 오염 방지)
exit 0
