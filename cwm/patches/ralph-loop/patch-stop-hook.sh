#!/bin/bash
# ralph-loop stop-hook 세션 격리 로컬 패치 적용기
# - 대상: ~/.claude/plugins/marketplaces/*/plugins/ralph-loop/hooks/stop-hook.sh
# - 효과: session_id 필드가 비어있을 때 block 대신 exit 0 + 경고
# - 성질: idempotent, 드리프트 감지, 실패 시 자동 롤백
# - 사용: bash patch-stop-hook.sh [--force]
# - 배포: CWM 플러그인 번들 (v2.4.2+)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECTED_SHA="13c547e77956e44f6af41d1be140f55da0e1ee3c55a540b530f48ee7c7ba9a11"
MARKER="[CWM-LOCAL-PATCH session-isolation v1]"
TARGET_LINE='if [[ -n "$STATE_SESSION" ]] && [[ "$STATE_SESSION" != "$HOOK_SESSION" ]]; then'
SNAP_DIR="$HERE/snapshots"
FORCE="${1:-}"

log() { printf '[patch] %s\n' "$*" >&2; }
die() { printf '[patch] ERROR: %s\n' "$*" >&2; exit 1; }

# ralph-loop 훅 탐색 (여러 마켓플레이스 지원)
find_hook() {
  local c
  for c in "$HOME"/.claude/plugins/marketplaces/*/plugins/ralph-loop/hooks/stop-hook.sh; do
    [[ -f "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

PLUGIN_HOOK="$(find_hook)" || {
  log "ralph-loop 이 설치되어 있지 않습니다. 패치 불필요."
  exit 0
}
log "target: $PLUGIN_HOOK"

# 이미 패치 적용됨?
if grep -qF "$MARKER" "$PLUGIN_HOOK"; then
  log "already applied — nothing to do."
  exit 0
fi

# 원본 타겟 라인 존재?
if ! grep -qF "$TARGET_LINE" "$PLUGIN_HOOK"; then
  log "target line not found. upstream may have already fixed this."
  log "expected to find: $TARGET_LINE"
  exit 0
fi

CUR_SHA=$(shasum -a 256 "$PLUGIN_HOOK" | awk '{print $1}')
if [[ "$CUR_SHA" != "$EXPECTED_SHA" ]] && [[ "$FORCE" != "--force" ]]; then
  log "SHA256 drift detected:"
  log "  expected: $EXPECTED_SHA"
  log "  actual:   $CUR_SHA"
  log "plugin likely updated. inspect L27-35 manually and rerun with --force if still applicable."
  exit 2
fi

mkdir -p "$SNAP_DIR"
BACKUP="$SNAP_DIR/stop-hook.${CUR_SHA:0:12}.orig"
if [[ ! -f "$BACKUP" ]]; then
  cp "$PLUGIN_HOOK" "$BACKUP"
  log "backup saved: $BACKUP"
else
  log "backup already exists: $BACKUP"
fi

TMP="$(mktemp "${TMPDIR:-/tmp}/patch-stop-hook.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

awk -v target="$TARGET_LINE" '
  BEGIN { replaced = 0 }
  index($0, target) == 1 && replaced == 0 {
    print "# [CWM-LOCAL-PATCH session-isolation v1] — remove when upstream lands"
    print "if [[ -n \"$STATE_SESSION\" ]]; then"
    print "  if [[ \"$STATE_SESSION\" != \"$HOOK_SESSION\" ]]; then"
    print "    exit 0"
    print "  fi"
    print "else"
    print "  if echo \"$FRONTMATTER\" | grep -q \"^session_id:\"; then"
    print "    echo \"⚠️  Ralph loop: session_id field is empty — refusing to block other sessions (CWM local patch)\" >&2"
    print "    exit 0"
    print "  fi"
    print "  # session_id 키 자체가 없는 레거시 파일만 fall-through"
    print "fi"
    print "# [/CWM-LOCAL-PATCH]"
    getline  # skip original "  exit 0"
    getline  # skip original "fi"
    replaced = 1
    next
  }
  { print }
  END {
    if (replaced == 0) {
      print "AWK_PATCH_FAILED: target line not found" > "/dev/stderr"
      exit 3
    }
  }
' "$PLUGIN_HOOK" > "$TMP"

if ! bash -n "$TMP"; then
  die "patched file failed bash syntax check; original left intact at $PLUGIN_HOOK"
fi

if ! grep -qF "$MARKER" "$TMP"; then
  die "marker missing after patch; aborting"
fi

cp "$TMP" "$PLUGIN_HOOK"
chmod +x "$PLUGIN_HOOK"

log "patch applied successfully."
log "rollback: cp '$BACKUP' '$PLUGIN_HOOK'"
