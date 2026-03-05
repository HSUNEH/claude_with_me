#!/usr/bin/env bash
# demo-plan-guard.sh — 계획 없이 코딩 시도 → 차단 + 안내 시뮬레이션
# Usage: bash demo-plan-guard.sh

set -euo pipefail

# ── ANSI Colors ──
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
YELLOW='\033[33m'
WHITE='\033[97m'
RESET='\033[0m'

LINE="───────────────────────────────────────────"

clear

# ── 사용자 프롬프트 입력 시뮬레이션 ──
echo ""
printf "${BOLD}${CYAN}❯${RESET} ${BOLD}${WHITE}"
sleep 0.8

# 타이핑 효과
TEXT="로그인 기능 만들어줘"
for (( i=0; i<${#TEXT}; i++ )); do
    printf "%s" "${TEXT:$i:1}"
    sleep 0.06
done
printf "${RESET}"
sleep 0.5
echo ""

# ── Enter 후 Hook 실행 시뮬레이션 ──
sleep 0.6

# plan-guard 출력
echo ""
printf "${DIM}"
cat <<'MSG'
───────────────────────────────────────────
⚠️ [계획 관리] 계획서가 없습니다
───────────────────────────────────────────

💡 /plan-manager 로 3문서를 생성하면 체계적으로 작업할 수 있습니다.
───────────────────────────────────────────
MSG
printf "${RESET}"

sleep 1.0

# ── Claude 응답 시뮬레이션 ──
echo ""
printf "${BOLD}${WHITE}"
sleep 0.3

RESPONSE='로그인 기능 개발을 시작하기 전에 계획을 먼저 수립해야 합니다.

어떻게 진행할까요?

  1. /plan-manager로 계획 수립 (권장)
  2. 바로 진행'

while IFS= read -r line; do
    echo "$line"
    sleep 0.08
done <<< "$RESPONSE"

printf "${RESET}"
echo ""
sleep 1.5
