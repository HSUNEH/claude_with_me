#!/bin/bash
# 패치 동작 스모크 테스트
# - case-A: session_id 다른 값  → exit 0 (기존 격리 동작 유지)
# - case-B: session_id 빈값     → exit 0 + stderr 경고 (패치 효과)
# - case-C: session_id 키 없음  → fall-through (기존 동작 유지)

set -euo pipefail

find_hook() {
  local c
  for c in "$HOME"/.claude/plugins/marketplaces/*/plugins/ralph-loop/hooks/stop-hook.sh; do
    [[ -f "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

PLUGIN_HOOK="$(find_hook)" || {
  echo "[test] ralph-loop 미설치 — 테스트 스킵"
  exit 0
}

FAIL=0

run_case() {
  local name="$1"
  local frontmatter="$2"
  local expect_warn="$3"
  local scratch
  scratch=$(mktemp -d "${TMPDIR:-/tmp}/ralph-test.XXXXXX")
  mkdir -p "$scratch/.claude"
  {
    printf -- '---\n'
    printf '%s' "$frontmatter"
    printf -- '\n---\n\n무관한 프롬프트\n'
  } > "$scratch/.claude/ralph-loop.local.md"

  local out err exit_code=0
  out=$(mktemp); err=$(mktemp)
  (
    cd "$scratch"
    echo '{"session_id":"test-other-xyz","transcript_path":"/dev/null"}' \
      | bash "$PLUGIN_HOOK" >"$out" 2>"$err"
  ) || exit_code=$?

  local warn_seen="no"
  if grep -q "session_id field is empty" "$err"; then warn_seen="yes"; fi

  local ok="PASS"
  if [[ "$exit_code" -ne 0 ]]; then ok="FAIL(exit=$exit_code)"; fi
  if [[ "$warn_seen" != "$expect_warn" ]]; then ok="FAIL(warn=$warn_seen,expect=$expect_warn)"; fi

  printf '  [%s] %-8s exit=%d warn=%s\n' "$ok" "$name" "$exit_code" "$warn_seen"
  if [[ "$ok" != PASS ]]; then
    echo "    --- stdout ---" ; sed 's/^/    /' < "$out"
    echo "    --- stderr ---" ; sed 's/^/    /' < "$err"
    FAIL=1
  fi

  rm -rf "$scratch" "$out" "$err"
}

echo "[test] plugin hook: $PLUGIN_HOOK"
run_case "case-A" 'active: true
iteration: 1
max_iterations: 0
completion_promise: null
session_id: abc123' "no"

run_case "case-B" 'active: true
iteration: 1
max_iterations: 0
completion_promise: null
session_id: ' "yes"

run_case "case-C" 'active: true
iteration: 1
max_iterations: 0
completion_promise: null' "no"

if [[ "$FAIL" -eq 0 ]]; then
  echo "[test] ALL PASS"
  exit 0
else
  echo "[test] FAILED"
  exit 1
fi
