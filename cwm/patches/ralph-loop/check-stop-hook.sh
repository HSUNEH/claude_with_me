#!/bin/bash
# ralph-loop stop-hook 패치 상태 점검
# exit codes: 0=patched, 1=not patched, 2=ralph-loop 미설치

set -euo pipefail

MARKER="[CWM-LOCAL-PATCH session-isolation v1]"

find_hook() {
  local c
  for c in "$HOME"/.claude/plugins/marketplaces/*/plugins/ralph-loop/hooks/stop-hook.sh; do
    [[ -f "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

PLUGIN_HOOK="$(find_hook)" || {
  echo "status:  NOT INSTALLED (ralph-loop 이 설치되어 있지 않음)"
  exit 2
}

CUR_SHA=$(shasum -a 256 "$PLUGIN_HOOK" | awk '{print $1}')
echo "file:    $PLUGIN_HOOK"
echo "sha256:  $CUR_SHA"

if grep -qF "$MARKER" "$PLUGIN_HOOK"; then
  echo "status:  PATCHED"
  exit 0
else
  echo "status:  NOT PATCHED"
  exit 1
fi
