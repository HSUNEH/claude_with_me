#!/usr/bin/env bash
# demo-simple-mode.sh — 간단한 작업 시뮬레이션 (확인 → 사용자 승인 → 수정)
set -euo pipefail

BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
WHITE='\033[97m'
GRAY='\033[90m'
RESET='\033[0m'
LINE="${DIM}──────────────────────────────────────────────${RESET}"

type_fast() {
    local text="$1"
    for (( i=0; i<${#text}; i++ )); do
        printf "%s" "${text:$i:1}"
        sleep 0.03
    done
}

prompt_user() {
    local text="$1"
    printf "\n${LINE}\n"
    printf "${BOLD}${WHITE}› ${RESET}"
    sleep 0.4
    printf "${BOLD}${WHITE}"
    type_fast "$text"
    printf "${RESET}\n"
    printf "${LINE}\n"
    sleep 0.3
}

clear
echo ""

# ── 사용자 입력 ──
printf "${LINE}\n"
printf "${BOLD}${WHITE}› ${RESET}"
sleep 0.4
printf "${BOLD}${WHITE}"
type_fast "헤더 색상 파란색으로 바꿔줘"
printf "${RESET}\n"
printf "${LINE}\n"
sleep 0.2
echo ""
sleep 0.3

# ── Claude: 간단 작업 확인 질문 ──
printf "${BOLD}${WHITE}간단한 수정으로 보입니다. 바로 진행할까요,${RESET}\n"
printf "${BOLD}${WHITE}아니면 /plan-manager로 새 계획을 수립할까요?${RESET}\n"
sleep 0.5

# ── 사용자: 승인 ──
prompt_user "바로 진행해줘"
sleep 0.3

# ── Claude: 수정 진행 ──
printf "\n${GRAY}  📝 src/components/Header.tsx 수정 중...${RESET}\n"
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
sleep 0.3
