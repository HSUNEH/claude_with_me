#!/usr/bin/env bash
# demo-plan-mode.sh — 사용자 요청 → 계획 모드 실행 시뮬레이션
set -euo pipefail

BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
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
type_fast "로그인 기능 만들어줘"
printf "${RESET}"
sleep 0.3
echo ""
sleep 0.3

# ── plan-guard Hook ──
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
sleep 0.5

# ── Claude 응답: plan-manager 실행 ──
echo ""
printf "${BOLD}${WHITE}계획을 먼저 수립하겠습니다. /plan-manager 실행 중...${RESET}\n"
sleep 0.5

echo ""
printf "${GRAY}  ✍️  요구사항 분석 중...${RESET}\n"
sleep 0.3
printf "${GRAY}  📐 구현 전략 설계 중...${RESET}\n"
sleep 0.3
printf "${GRAY}  📄 3문서 생성 중...${RESET}\n"
sleep 0.4

# ── 3문서 생성 결과 ──
echo ""
cat <<'MSG'
📂 docs/plans/user-auth/
  ├── PLAN.md       ← 전체 구현 계획
  ├── CONTEXT.md    ← 결정 근거
  └── CHECKLIST.md  ← 작업 체크리스트 (🔴 시작 전)

[계획 요약]
  Phase 1: Prisma 스키마 & 인증 API
  Phase 2: 로그인/회원가입 UI
  Phase 3: JWT 미들웨어 & 보호 라우트
  Phase 4: 테스트 & 에러 처리
MSG
sleep 0.5

echo ""
printf "${BOLD}${YELLOW}⏸️ 검토 후 승인해주세요.${RESET}\n"
printf "   승인 전까지 코드 작성을 시작하지 않습니다.\n"
sleep 1.0
