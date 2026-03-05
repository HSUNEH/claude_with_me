#!/usr/bin/env bash
# demo-auto-manual.sh — pre-prompt-check 매뉴얼 추천 시뮬레이션
# Usage: bash demo-auto-manual.sh

set -euo pipefail

# ── ANSI Colors ──
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
YELLOW='\033[33m'
WHITE='\033[97m'
GRAY='\033[90m'
RESET='\033[0m'

clear

# ── 사용자 프롬프트 입력 시뮬레이션 ──
echo ""
printf "${BOLD}${CYAN}❯${RESET} ${BOLD}${WHITE}"
sleep 0.8

TEXT="사용자 인증 API 만들어줘"
for (( i=0; i<${#TEXT}; i++ )); do
    printf "%s" "${TEXT:$i:1}"
    sleep 0.06
done
printf "${RESET}"
sleep 0.5
echo ""

# ── Hook 실행 시뮬레이션 ──
sleep 0.6
echo ""

printf "${DIM}"
cat <<'MSG'
───────────────────────────────────────────
📋 [자동 매뉴얼] 작업 시작 전 체크
───────────────────────────────────────────

감지된 의도: API 개발
추천 챕터:   2(코딩 표준), 3(아키텍처), 4(에러 처리), 5(보안)

파일 감지:   src/api/ (api 레이어)
중점 검사:   인증 로직, 입력 검증, 에러 응답 형식

→ /dev-manual 에서 위 챕터를 읽고 작업을 시작하세요.
  경로: .claude/skills/dev-manual/chapters/
───────────────────────────────────────────
MSG
printf "${RESET}"

sleep 1.0

# ── Claude 응답 시뮬레이션 ──
echo ""
printf "${BOLD}${WHITE}"
sleep 0.3

RESPONSE='매뉴얼을 먼저 확인하겠습니다.

📖 챕터 2 (코딩 표준) 읽는 중...
📖 챕터 3 (아키텍처) 읽는 중...
📖 챕터 4 (에러 처리) 읽는 중...
📖 챕터 5 (보안) 읽는 중...

매뉴얼을 참고하여 사용자 인증 API를 구현하겠습니다.
인증 방식은 JWT, 에러 처리는 커스텀 에러 클래스를 사용합니다.'

while IFS= read -r line; do
    echo "$line"
    sleep 0.1
done <<< "$RESPONSE"

printf "${RESET}"
echo ""
sleep 1.5
