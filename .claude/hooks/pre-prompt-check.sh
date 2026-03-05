#!/bin/bash
# ============================================================
# [UserPromptSubmit Hook] 작업 시작 전 매뉴얼 리마인더
# ============================================================
# 매칭 조건 활용:
#   1. 키워드 → 개발 관련 프롬프트인지 필터링
#   2. 의도 파악 → 작업 유형 자동 분류 → 챕터 추천
#   3. 작업 위치 → 프롬프트에 언급된 파일 경로 → 검사 중점 안내
# ============================================================

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# 매칭 유틸리티 로드
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/matcher.sh"

# ── 1. 키워드 매칭: 개발 관련이 아니면 스킵
KEYWORD_TYPE=$(match_keywords "$PROMPT")
if [ "$KEYWORD_TYPE" = "none" ]; then
  exit 0
fi

# ── 2. 의도 파악: 작업 유형 자동 분류
INTENT=$(detect_intent "$PROMPT")
CHAPTERS=$(intent_to_chapters "$INTENT")

# 의도별 한글 라벨 (config.yml에서 읽기)
INTENT_LABEL=$(intent_to_label "$INTENT")

# ── 3. 작업 위치: 프롬프트에서 파일 경로 추출
FILE_MENTION=$(echo "$PROMPT" | grep -oE '[a-zA-Z0-9_/.-]+\.(ts|tsx|js|jsx|py|vue|svelte|css|json)' | head -1)
LOCATION_INFO=""
if [ -n "$FILE_MENTION" ]; then
  LOCATION=$(detect_location "$FILE_MENTION")
  FOCUS=$(location_to_focus "$LOCATION")
  LOCATION_INFO="파일 감지: ${FILE_MENTION} (${LOCATION} 레이어)
  중점 검사: ${FOCUS}"
fi

# ── 출력
cat <<MSG
───────────────────────────────────────────
📋 [자동 매뉴얼] 작업 시작 전 체크
───────────────────────────────────────────

감지된 의도: ${INTENT_LABEL}
추천 챕터:   ${CHAPTERS}
${LOCATION_INFO:+
${LOCATION_INFO}
}
→ /dev-manual 에서 위 챕터를 읽고 작업을 시작하세요.
  경로: .claude/skills/dev-manual/chapters/
───────────────────────────────────────────
MSG

exit 0
