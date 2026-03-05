#!/usr/bin/env bash
# demo-plan-resume.sh — 계획 승인 → /clear → "이어서 구현해줘" → 구현 시작 시뮬레이션
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

type_user() {
    printf "\n${BOLD}${CYAN}❯${RESET} ${BOLD}${WHITE}"
    type_fast "$1"
    printf "${RESET}\n"
    sleep 0.3
}

clear
echo ""

# ── 사용자: 승인 ──
printf "${BOLD}${CYAN}❯${RESET} ${BOLD}${WHITE}"
type_fast "승인"
printf "${RESET}"
sleep 0.2
echo ""
sleep 0.3

# ── Claude: 승인 처리 ──
echo ""
cat <<MSG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${BOLD}✅ 계획이 승인되었습니다${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📂 CHECKLIST.md → 🟡 진행 중

💡 /clear 로 컨텍스트를 정리한 뒤 작업을 시작하세요.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MSG
sleep 0.8

# ── /clear 실행 ──
type_user "/clear"
sleep 0.3

printf "${GRAY}── 컨텍스트 초기화 완료 ──${RESET}\n"
sleep 0.4

# ── 새 세션: 이어서 구현해줘 ──
type_user "이어서 구현해줘"
sleep 0.3

# ── plan-guard Hook: 진행 중 감지 ──
echo ""
printf "${DIM}"
cat <<'MSG'
───────────────────────────────────────────
📋 [컨텍스트] user-auth (🟡 진행 중)
───────────────────────────────────────────

진행: 0/12 완료
현재: Phase 1: Prisma 스키마 & 인증 API

남은 작업:
  · User 모델 스키마 정의
  · 회원가입 API (/api/auth/register)
  · 로그인 API (/api/auth/login)

📂 docs/plans/user-auth/
   → PLAN.md, CHECKLIST.md를 읽고 이어서 작업하세요.
───────────────────────────────────────────
MSG
printf "${RESET}"
sleep 0.5

# ── Claude: 계획 읽고 구현 시작 ──
echo ""
printf "${BOLD}${WHITE}"
cat <<'MSG'
PLAN.md, CHECKLIST.md 확인 완료.
Phase 1부터 시작합니다.

📄 prisma/schema.prisma 생성 중...
MSG
printf "${RESET}"
sleep 1.0
