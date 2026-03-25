#!/bin/bash
# ============================================================
# [SessionStart Hook] CWM HUD 자동 설정
# ============================================================
# 플러그인 설치 시 statusLine을 CWM HUD로 자동 구성.
# 이미 설정되어 있으면 건드리지 않음.
# ============================================================

SETTINGS_FILE="$HOME/.claude/settings.json"
HUD_SCRIPT="${CLAUDE_PLUGIN_ROOT}/hud/cwm-hud.mjs"

# settings.json 없으면 생성
if [ ! -f "$SETTINGS_FILE" ]; then
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  echo '{}' > "$SETTINGS_FILE"
fi

# 이미 statusLine이 설정되어 있으면 스킵
if command -v jq &>/dev/null; then
  EXISTING=$(jq -r '.statusLine // empty' "$SETTINGS_FILE" 2>/dev/null)
  if [ -n "$EXISTING" ] && [ "$EXISTING" != "null" ]; then
    exit 0
  fi

  # statusLine 추가
  jq --arg cmd "node ${HUD_SCRIPT}" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
fi

exit 0
