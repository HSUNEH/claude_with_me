#!/bin/bash
# ============================================================
# config.yml 파서 — YAML을 bash에서 읽기 위한 경량 유틸
# ============================================================
# 순수 bash로 구현. 외부 의존성 없음 (yq/python 불필요)
# 지원: 단순 key: value, 중첩 key, 목록(- item)
# ============================================================

# config.yml 경로 결정
_find_config() {
  local SEARCH_DIR="${CWD:-.}"
  local CONFIG_PATH="$SEARCH_DIR/.claude/hooks/config.yml"

  if [ -f "$CONFIG_PATH" ]; then
    echo "$CONFIG_PATH"
    return 0
  fi

  # Hook 스크립트 위치 기준으로도 탐색
  local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-$0}")" && pwd)"
  CONFIG_PATH="$(dirname "$SCRIPT_DIR")/hooks/config.yml"
  if [ -f "$CONFIG_PATH" ]; then
    echo "$CONFIG_PATH"
    return 0
  fi

  CONFIG_PATH="$SCRIPT_DIR/../config.yml"
  if [ -f "$CONFIG_PATH" ]; then
    echo "$CONFIG_PATH"
    return 0
  fi

  return 1
}

# 범용 값 읽기 (내부 함수)
# 1-depth: _cfg_read_value "section" "key"
# 2-depth: _cfg_read_value "section" "target" "field"
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

# 단순 값 읽기: cfg_get "section.key"
# 예: cfg_get "general.change_log_path" → "docs/logs/change-log.md"
cfg_get() {
  local KEY_PATH="$1"
  local SECTION="${KEY_PATH%%.*}"
  local KEY="${KEY_PATH#*.}"
  _cfg_read_value "$SECTION" "$KEY"
}

# 키워드 패턴 읽기: cfg_get_keywords "dev"
cfg_get_keywords() {
  _cfg_read_value "keywords" "$1"
}

# 의도 패턴/라벨/챕터 읽기: cfg_get_intent_field "bugfix" "patterns"
cfg_get_intent_field() {
  _cfg_read_value "intents" "$1" "$2"
}

# 위치 설정 읽기: cfg_get_location_field "api" "focus"
cfg_get_location_field() {
  _cfg_read_value "locations" "$1" "$2"
}

# 코드 패턴 읽기: cfg_get_code_pattern "security_dangerous_functions" "pattern"
cfg_get_code_pattern() {
  _cfg_read_value "code_patterns" "$1" "$2"
}

# general 섹션 값 읽기: cfg_get_general "require_plan" → "true"
cfg_get_general() {
  _cfg_read_value "general" "$1"
}

# 완료 검사 임계값 읽기
cfg_get_threshold() {
  _cfg_read_value "completion_check" "$1"
}

# 체크리스트 읽기: cfg_get_checklist "api" → 줄바꿈 구분 목록
cfg_get_checklist() {
  local LOC="$1"
  local CONFIG_FILE=$(_find_config)
  [ -z "$CONFIG_FILE" ] && return 1

  awk -v loc="$LOC" '
    BEGIN { in_locations=0; in_target=0; in_checklist=0 }
    /^locations:/ { in_locations=1; next }
    /^[a-z]/ && !/^locations:/ { if (in_locations) { in_locations=0; in_target=0 } }
    in_locations && /^  [a-z_]+:/ {
      sub(/^  /, ""); k=$0; gsub(/:.*/, "", k)
      in_target = (k == loc) ? 1 : 0
      in_checklist=0; next
    }
    in_target && /^    checklist:/ { in_checklist=1; next }
    in_target && in_checklist && /^      - / {
      v=$0; sub(/^      - /, "", v)
      gsub(/^["'"'"']|["'"'"']$/, "", v)
      print v
    }
    in_target && in_checklist && !/^      - / && !/^$/ { in_checklist=0 }
  ' "$CONFIG_FILE"
}

# intents 섹션의 의도 이름 목록 추출: cfg_list_intents → "new_feature bugfix refactor ..."
cfg_list_intents() {
  local CONFIG_FILE=$(_find_config)
  [ -z "$CONFIG_FILE" ] && return 1

  awk '
    BEGIN { in_intents=0 }
    /^intents:/ { in_intents=1; next }
    /^[a-z]/ && !/^intents:/ { if (in_intents) exit }
    in_intents && /^  [a-z_]+:/ {
      sub(/^  /, ""); gsub(/:.*/, "")
      printf "%s ", $0
    }
  ' "$CONFIG_FILE"
}

# locations 섹션의 위치 이름 목록 추출: cfg_list_locations → "ui api service ..."
cfg_list_locations() {
  local CONFIG_FILE=$(_find_config)
  [ -z "$CONFIG_FILE" ] && return 1

  awk '
    BEGIN { in_locations=0 }
    /^locations:/ { in_locations=1; next }
    /^[a-z]/ && !/^locations:/ { if (in_locations) exit }
    in_locations && /^  [a-z_]+:/ {
      sub(/^  /, ""); gsub(/:.*/, "")
      printf "%s ", $0
    }
  ' "$CONFIG_FILE"
}
