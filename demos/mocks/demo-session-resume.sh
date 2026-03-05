#!/usr/bin/env bash
# demo-session-resume.sh — plan-guard 진행 중 계획 감지 시뮬레이션
# Usage: bash demo-session-resume.sh

set -euo pipefail

# ── ANSI Colors ──
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
WHITE='\033[97m'
GRAY='\033[90m'
RESET='\033[0m'

clear

# ── 새 세션 시작 시뮬레이션 ──
echo ""
printf "${GRAY}── 새 Claude Code 세션 시작 ──${RESET}\n"
sleep 0.8
echo ""

# ── 사용자 프롬프트 입력 ──
printf "${BOLD}${CYAN}❯${RESET} ${BOLD}${WHITE}"
sleep 0.6

TEXT="이어서 구현해줘"
for (( i=0; i<${#TEXT}; i++ )); do
    printf "%s" "${TEXT:$i:1}"
    sleep 0.06
done
printf "${RESET}"
sleep 0.5
echo ""

# ── plan-guard Hook 실행 ──
sleep 0.6
echo ""

printf "${DIM}"
cat <<'MSG'
───────────────────────────────────────────
📋 [컨텍스트] user-auth (🟡 진행 중)
───────────────────────────────────────────

진행: 5/12 완료
현재: Phase 3: JWT 미들웨어 & 보호 라우트

남은 작업:
  · JWT 토큰 검증 미들웨어 구현
  · 보호 라우트에 미들웨어 적용
  · 토큰 갱신 API 작성
  · 로그아웃 처리 (토큰 무효화)

📂 docs/plans/user-auth/
   → PLAN.md, CHECKLIST.md를 읽고 이어서 작업하세요.
───────────────────────────────────────────
MSG
printf "${RESET}"

sleep 1.0

# ── Claude 응답 시뮬레이션 ──
echo ""
printf "${BOLD}${WHITE}"
sleep 0.3

RESPONSE='user-auth 작업을 이어서 진행하겠습니다.

📂 CHECKLIST.md 확인 중...

현재 Phase 3의 미완료 작업부터 시작합니다:
  1. JWT 토큰 검증 미들웨어 구현
  2. 보호 라우트에 미들웨어 적용

src/middleware/auth.ts 파일을 생성하겠습니다.'

while IFS= read -r line; do
    echo "$line"
    sleep 0.1
done <<< "$RESPONSE"

printf "${RESET}"
echo ""
sleep 1.5
