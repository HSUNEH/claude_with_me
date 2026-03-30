#!/bin/bash
# ============================================================
# CWM config.yml parser
# ============================================================
# .cwm/config.yml → plugin default fallback
# ============================================================

_find_config() {
  local SEARCH_DIR="${PROJECT_ROOT:-${CWD:-.}}"

  # Project-level config
  local CONFIG_PATH="$SEARCH_DIR/.cwm/config.yml"
  if [ -f "$CONFIG_PATH" ]; then
    echo "$CONFIG_PATH"
    return 0
  fi

  # Plugin default (CLAUDE_PLUGIN_ROOT)
  local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-$0}")" && pwd)"
  CONFIG_PATH="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/templates/config.yml"
  if [ -f "$CONFIG_PATH" ]; then
    echo "$CONFIG_PATH"
    return 0
  fi

  return 1
}

_cfg_read_value() {
  local CONFIG_FILE=$(_find_config)
  [ -z "$CONFIG_FILE" ] && return 1

  if [ $# -eq 2 ]; then
    local SECTION="$1" KEY="$2"
    awk -v section="$SECTION" -v key="$KEY" '
      BEGIN { in_section=0 }
      /^[a-z_]+:/ {
        if ($1 == section":") { in_section=1; next }
        else if (in_section) { in_section=0 }
      }
      in_section && /^  [a-z_]+:/ {
        sub(/^  /, "")
        split($0, kv, ": ")
        k = kv[1]; gsub(/:$/, "", k)
        if (k == key) {
          v = $0; sub(/^[^:]+: */, "", v)
          gsub(/^["'"'"']|["'"'"']$/, "", v)
          print v; exit
        }
      }
    ' "$CONFIG_FILE"
  elif [ $# -eq 3 ]; then
    local SECTION="$1" TARGET="$2" FIELD="$3"
    awk -v section="$SECTION" -v target="$TARGET" -v field="$FIELD" '
      BEGIN { in_section=0; in_target=0 }
      /^[a-z_]+:/ {
        if ($1 == section":") { in_section=1; next }
        else if (in_section) { in_section=0; in_target=0 }
      }
      in_section && /^  [a-z_]+:/ {
        sub(/^  /, "")
        k = $0; gsub(/:.*/, "", k)
        in_target = (k == target) ? 1 : 0
        next
      }
      in_target && /^    [a-z_]+:/ {
        sub(/^    /, "")
        split($0, kv, ": ")
        k = kv[1]; gsub(/:$/, "", k)
        if (k == field) {
          v = $0; sub(/^[^:]+: */, "", v)
          gsub(/^["'"'"']|["'"'"']$/, "", v)
          print v; exit
        }
      }
    ' "$CONFIG_FILE"
  fi
}

cfg_get() {
  local KEY_PATH="$1"
  local SECTION="${KEY_PATH%%.*}"
  local KEY="${KEY_PATH#*.}"
  _cfg_read_value "$SECTION" "$KEY"
}

cfg_get_keywords() { _cfg_read_value "keywords" "$1"; }
cfg_get_intent_field() { _cfg_read_value "intents" "$1" "$2"; }
cfg_get_location_field() { _cfg_read_value "locations" "$1" "$2"; }
cfg_get_general() { _cfg_read_value "general" "$1"; }
cfg_get_threshold() { _cfg_read_value "completion_check" "$1"; }
