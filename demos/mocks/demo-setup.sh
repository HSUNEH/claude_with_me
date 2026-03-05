#!/usr/bin/env bash
# demo-setup.sh — /setup 위저드 5단계 압축 시뮬레이션
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
printf "${BOLD}${CYAN}❯${RESET} ${BOLD}${WHITE}"
type_fast "/setup"
printf "${RESET}"
sleep 0.3
echo ""
sleep 0.4

# ── 시작 배너 ──
cat <<'MSG'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 프로젝트 초기화 위저드를 시작합니다
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MSG

printf "\n  ${BOLD}Phase 1${RESET}  프로젝트 비전        ${YELLOW}← 지금${RESET}\n"
printf "  ${DIM}Phase 2  기술 환경${RESET}\n"
printf "  ${DIM}Phase 3  워크플로우 설정${RESET}\n"
printf "  ${DIM}Phase 4  초기 개발 계획${RESET}\n"
printf "  ${DIM}Phase 5  환경 세팅 적용${RESET}\n\n"
sleep 0.8

# ── Phase 1 ──
printf "${BOLD}📋 Phase 1: 프로젝트에 대해 알려주세요${RESET}\n\n"
sleep 0.2

printf "  ${CYAN}→${RESET} 이름: todo-app\n"
sleep 0.08
printf "  ${CYAN}→${RESET} 설명: 팀 협업용 할 일 관리 웹앱\n"
sleep 0.08
printf "  ${CYAN}→${RESET} 핵심 기능: 사용자 인증, 할 일 CRUD, 실시간 동기화\n"
sleep 0.08
printf "  ${CYAN}→${RESET} 첫 기능: 사용자 인증\n"
sleep 0.5

echo ""
echo "📌 프로젝트 비전 확인 ✓"
sleep 0.4

# ── Phase 2 ──
printf "\n${BOLD}📋 Phase 2: 기술 환경${RESET}\n\n"
sleep 0.2
printf "  ${CYAN}→${RESET} TypeScript + Next.js (App Router)\n"
sleep 0.06
printf "  ${CYAN}→${RESET} PostgreSQL + Prisma\n"
sleep 0.06
printf "  ${CYAN}→${RESET} pnpm / Vitest / ESLint + Prettier\n"
sleep 0.4

echo ""
echo "📌 기술 환경 확인 ✓"
sleep 0.4

# ── Phase 3 ──
printf "\n${BOLD}📋 Phase 3: 워크플로우${RESET}\n\n"
sleep 0.2
printf "  ${CYAN}→${RESET} camelCase / 커스텀 에러 클래스 / JWT / GitHub Flow\n"
sleep 0.4

echo ""
echo "📌 워크플로우 확인 ✓"
sleep 0.4

# ── Phase 4 ──
printf "\n${BOLD}📋 Phase 4: 초기 개발 계획${RESET}\n"
cat <<'MSG'

📂 docs/plans/user-auth/
  ├── PLAN.md       ← 전체 구현 계획
  ├── CONTEXT.md    ← 결정 근거
  └── CHECKLIST.md  ← 작업 체크리스트

MSG
sleep 0.5

# ── Phase 5 완료 ──
cat <<MSG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${BOLD}✅ 프로젝트 초기화 완료!${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 생성: todo-app/, CLAUDE.md, config.yml, 매뉴얼 6개, 계획 3문서

💡 /clear 후 "시작해줘" 라고 하면 개발이 시작됩니다.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MSG
sleep 1.0
