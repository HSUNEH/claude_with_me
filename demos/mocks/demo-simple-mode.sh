#!/usr/bin/env bash
# demo-simple-mode.sh — 간단한 작업 시뮬레이션
set -euo pipefail

BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
WHITE='\033[97m'
GRAY='\033[90m'
RESET='\033[0m'

type_fast() {
    local text="$1"
    for (( i=0; i<${#text}; i++ )); do
        printf "%s" "${text:$i:1}"
        sleep 0.03
    done
}

clear
echo ""

# ── 사용자 입력 ──
printf "${BOLD}${CYAN}❯${RESET} ${BOLD}${WHITE}"
type_fast "헤더 색상 파란색으로 바꿔줘"
printf "${RESET}"
sleep 0.2
echo ""
sleep 0.3

# ── Claude 응답: 간단 작업 확인 ──
echo ""
printf "${BOLD}${WHITE}간단한 수정입니다. 바로 진행하겠습니다.${RESET}\n"
sleep 0.4

echo ""
printf "${GRAY}  📝 src/components/Header.tsx 수정 중...${RESET}\n"
sleep 0.3

# ── 코드 변경 ──
echo ""
printf "${GREEN}+${RESET} className=\"bg-blue-600 text-white\"\n"
printf "${DIM}-${RESET} ${DIM}className=\"bg-gray-800 text-white\"${RESET}\n"
sleep 0.4

# ── completion-checker 통과 ──
echo ""
printf "${DIM}"
cat <<'MSG'
───────────────────────────────────────────
✅ [완료 후 검사] 모든 검사 통과
───────────────────────────────────────────
린트/타입 체크 통과, 코드 패턴 경고 없음.
───────────────────────────────────────────
MSG
printf "${RESET}"
sleep 0.4

echo ""
printf "${BOLD}${WHITE}헤더 색상을 파란색으로 변경했습니다.${RESET}\n"
sleep 1.0
