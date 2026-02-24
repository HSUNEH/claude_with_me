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

# 단순 값 읽기: cfg_get "section.key"
# 예: cfg_get "general.change_log_path" → "docs/logs/change-log.md"
cfg_get() {
  local KEY_PATH="$1"
  local CONFIG_FILE=$(_find_config)
  [ -z "$CONFIG_FILE" ] && return 1

  local SECTION=$(echo "$KEY_PATH" | cut -d'.' -f1)
  local KEY=$(echo "$KEY_PATH" | cut -d'.' -f2-)

  # 섹션 내에서 키 찾기
  awk -v section="$SECTION" -v key="$KEY" '
    BEGIN { in_section=0; found=0 }
    /^[a-z_]+:/ {
      if ($1 == section":") { in_section=1; next }
      else if (in_section) { in_section=0 }
    }
    in_section && /^  [a-z_]+:/ {
      sub(/^  /, "")
      split($0, kv, ": ")
      k = kv[1]
      gsub(/:$/, "", k)
      if (k == key) {
        v = $0
        sub(/^[^:]+: */, "", v)
        gsub(/^["'"'"']|["'"'"']$/, "", v)
        print v
        found=1
        exit
      }
    }
    END { if (!found) exit 1 }
  ' "$CONFIG_FILE"
}

# 키워드 패턴 읽기: cfg_get_keywords "dev"
cfg_get_keywords() {
  local CATEGORY="$1"
  local CONFIG_FILE=$(_find_config)
  [ -z "$CONFIG_FILE" ] && return 1

  awk -v cat="$CATEGORY" '
    BEGIN { in_keywords=0 }
    /^keywords:/ { in_keywords=1; next }
    /^[a-z]/ && !/^keywords:/ { if (in_keywords) in_keywords=0 }
    in_keywords {
      sub(/^  /, "")
      split($0, kv, ": ")
      k = kv[1]
      gsub(/:$/, "", k)
      if (k == cat) {
        v = $0
        sub(/^[^:]+: */, "", v)
        gsub(/^["'"'"']|["'"'"']$/, "", v)
        print v
        exit
      }
    }
  ' "$CONFIG_FILE"
}

# 의도 패턴/라벨/챕터 읽기: cfg_get_intent_field "bugfix" "patterns"
cfg_get_intent_field() {
  local INTENT="$1"
  local FIELD="$2"
  local CONFIG_FILE=$(_find_config)
  [ -z "$CONFIG_FILE" ] && return 1

  awk -v intent="$INTENT" -v field="$FIELD" '
    BEGIN { in_intents=0; in_target=0 }
    /^intents:/ { in_intents=1; next }
    /^[a-z]/ && !/^intents:/ { if (in_intents) { in_intents=0; in_target=0 } }
    in_intents && /^  [a-z_]+:/ {
      sub(/^  /, "")
      k = $0; gsub(/:.*/, "", k)
      in_target = (k == intent) ? 1 : 0
      next
    }
    in_target && /^    [a-z_]+:/ {
      sub(/^    /, "")
      split($0, kv, ": ")
      k = kv[1]; gsub(/:$/, "", k)
      if (k == field) {
        v = $0; sub(/^[^:]+: */, "", v)
        gsub(/^["'"'"']|["'"'"']$/, "", v)
        print v
        exit
      }
    }
  ' "$CONFIG_FILE"
}

# 위치 설정 읽기: cfg_get_location_field "api" "focus"
cfg_get_location_field() {
  local LOC="$1"
  local FIELD="$2"
  local CONFIG_FILE=$(_find_config)
  [ -z "$CONFIG_FILE" ] && return 1

  awk -v loc="$LOC" -v field="$FIELD" '
    BEGIN { in_locations=0; in_target=0 }
    /^locations:/ { in_locations=1; next }
    /^[a-z]/ && !/^locations:/ { if (in_locations) { in_locations=0; in_target=0 } }
    in_locations && /^  [a-z_]+:/ {
      sub(/^  /, "")
      k = $0; gsub(/:.*/, "", k)
      in_target = (k == loc) ? 1 : 0
      next
    }
    in_target && /^    [a-z_]+:/ {
      sub(/^    /, "")
      split($0, kv, ": ")
      k = kv[1]; gsub(/:$/, "", k)
      if (k == field) {
        v = $0; sub(/^[^:]+: */, "", v)
        gsub(/^["'"'"']|["'"'"']$/, "", v)
        print v
        exit
      }
    }
  ' "$CONFIG_FILE"
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

# 코드 패턴 읽기: cfg_get_code_pattern "security_dangerous_functions" "pattern"
cfg_get_code_pattern() {
  local NAME="$1"
  local FIELD="$2"
  local CONFIG_FILE=$(_find_config)
  [ -z "$CONFIG_FILE" ] && return 1

  awk -v name="$NAME" -v field="$FIELD" '
    BEGIN { in_cp=0; in_target=0 }
    /^code_patterns:/ { in_cp=1; next }
    /^[a-z]/ && !/^code_patterns:/ { if (in_cp) { in_cp=0; in_target=0 } }
    in_cp && /^  [a-z_]+:/ {
      sub(/^  /, ""); k=$0; gsub(/:.*/, "", k)
      in_target = (k == name) ? 1 : 0; next
    }
    in_target && /^    [a-z_]+:/ {
      sub(/^    /, "")
      split($0, kv, ": "); k=kv[1]; gsub(/:$/, "", k)
      if (k == field) {
        v=$0; sub(/^[^:]+: */, "", v)
        gsub(/^["'"'"']|["'"'"']$/, "", v)
        print v; exit
      }
    }
  ' "$CONFIG_FILE"
}

# 완료 검사 임계값 읽기
cfg_get_threshold() {
  local KEY="$1"
  local CONFIG_FILE=$(_find_config)
  [ -z "$CONFIG_FILE" ] && return 1

  awk -v key="$KEY" '
    BEGIN { in_cc=0 }
    /^completion_check:/ { in_cc=1; next }
    /^[a-z]/ && !/^completion_check:/ { if (in_cc) in_cc=0 }
    in_cc && /^  [a-z_]+:/ {
      sub(/^  /, "")
      split($0, kv, ": "); k=kv[1]; gsub(/:$/, "", k)
      if (k == key) { v=$0; sub(/^[^:]+: */, "", v); print v; exit }
    }
  ' "$CONFIG_FILE"
}
