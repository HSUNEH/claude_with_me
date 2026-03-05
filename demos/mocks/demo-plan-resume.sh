#!/usr/bin/env bash
# demo-plan-resume.sh — 계획 승인 → /clear → 재개 시뮬레이션
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

👉 /clear 후 "이어서 구현해줘" 라고 입력하세요.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MSG
sleep 0.8

# ── /clear 효과 ──
printf "\n${GRAY}── /clear 실행 → 새 컨텍스트 ──${RESET}\n"
sleep 0.5
echo ""

# ── 새 프롬프트 ──
printf "${BOLD}${CYAN}❯${RESET} ${BOLD}${WHITE}"
type_fast "이어서 구현해줘"
printf "${RESET}"
sleep 0.2
echo ""
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

# ── Claude 응답 ──
echo ""
printf "${BOLD}${WHITE}"
cat <<'MSG'
PLAN.md, CHECKLIST.md 확인 완료.
Phase 1부터 시작합니다.

📄 prisma/schema.prisma 생성 중...
MSG
printf "${RESET}"
sleep 1.0
