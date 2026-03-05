#!/usr/bin/env bash
# demo-setup.sh — /setup 위저드 5단계 시뮬레이션 (Phase별 사용자 응답 포함)
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
    # 빈 프롬프트 창 먼저 표시
    printf "\n${LINE}\n"
    printf "${BOLD}${WHITE}› ${RESET}"
    sleep 0.4
    # 사용자가 타이핑
    printf "${BOLD}${WHITE}"
    type_fast "$text"
    printf "${RESET}\n"
    printf "${LINE}\n"
    sleep 0.3
}

clear

# ── 사용자: /setup 입력 ──
printf "${LINE}\n"
printf "${BOLD}${WHITE}› ${RESET}"
sleep 0.4
printf "${BOLD}${WHITE}"
type_fast "/setup"
printf "${RESET}\n"
printf "${LINE}\n"
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

# ── Phase 1: 질문 ──
printf "${BOLD}📋 Phase 1: 프로젝트에 대해 알려주세요${RESET}\n\n"
sleep 0.2
printf "  1. 프로젝트 이름은?\n"
printf "  2. 한 문장으로 설명하면?\n"
printf "  3. 핵심 기능 3~5개\n"
printf "  4. 첫 번째로 만들고 싶은 기능은?\n"
sleep 0.6

# ── Phase 1: 사용자 응답 ──
prompt_user "todo-app / 팀 협업용 할 일 관리 웹앱 / 사용자 인증, 할 일 CRUD, 실시간 동기화 / 사용자 인증"
sleep 0.3

# ── Phase 1: 확인 ──
printf "\n📌 프로젝트 비전 확인:\n\n"
printf "  ${CYAN}→${RESET} 이름: todo-app\n"
printf "  ${CYAN}→${RESET} 설명: 팀 협업용 할 일 관리 웹앱\n"
printf "  ${CYAN}→${RESET} 핵심 기능: 사용자 인증, 할 일 CRUD, 실시간 동기화\n"
printf "  ${CYAN}→${RESET} 첫 작업: 사용자 인증\n\n"
printf "이대로 진행할까요?\n"
sleep 0.5

# ── Phase 1: 사용자 승인 ──
prompt_user "확인"
sleep 0.3

# ── Phase 2: 질문 + 응답 ──
printf "\n${BOLD}📋 Phase 2: 기술 환경${RESET}\n\n"
printf "  언어, 프레임워크, DB, 패키지 매니저, 테스트, 린터를 알려주세요.\n"
sleep 0.5

prompt_user "TypeScript + Next.js (App Router) / PostgreSQL + Prisma / pnpm / Vitest / ESLint + Prettier"
sleep 0.3

printf "\n📌 기술 환경 확인:\n\n"
printf "  ${CYAN}→${RESET} TypeScript + Next.js (App Router)\n"
printf "  ${CYAN}→${RESET} PostgreSQL + Prisma\n"
printf "  ${CYAN}→${RESET} pnpm / Vitest / ESLint + Prettier\n\n"
printf "이대로 진행할까요?\n"
sleep 0.5

prompt_user "확인"
sleep 0.3

# ── Phase 3: 질문 + 응답 ──
printf "\n${BOLD}📋 Phase 3: 워크플로우${RESET}\n\n"
printf "  코딩 규칙, 에러 처리, 보안, Git 전략을 알려주세요.\n"
printf "  (특별한 규칙이 없으면 \"기본\")\n"
sleep 0.5

prompt_user "camelCase / 커스텀 에러 클래스 / JWT / GitHub Flow / 나머지 기본"
sleep 0.3

printf "\n📌 워크플로우 확인:\n\n"
printf "  ${CYAN}→${RESET} 네이밍: camelCase\n"
printf "  ${CYAN}→${RESET} 에러: 커스텀 에러 클래스\n"
printf "  ${CYAN}→${RESET} 인증: JWT\n"
printf "  ${CYAN}→${RESET} 브랜치: GitHub Flow\n\n"
printf "이대로 진행할까요?\n"
sleep 0.5

prompt_user "확인"
sleep 0.3

# ── Phase 4: 계획 생성 ──
printf "\n${BOLD}📋 Phase 4: 초기 개발 계획${RESET}\n\n"
printf "첫 번째 기능 \"사용자 인증\"의 개발 계획을 수립했습니다.\n"
cat <<'MSG'

📂 docs/plans/user-auth/
  ├── PLAN.md       ← 전체 구현 계획
  ├── CONTEXT.md    ← 결정 근거
  └── CHECKLIST.md  ← 작업 체크리스트

MSG
printf "계획을 검토해주세요.\n"
sleep 0.5

prompt_user "확인"
sleep 0.3

# ── Phase 5 완료 ──
cat <<MSG

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${BOLD}✅ 프로젝트 초기화 완료!${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 생성: todo-app/, CLAUDE.md, config.yml, 매뉴얼 6개, 계획 3문서

💡 /clear 후 "시작해줘" 라고 하면 개발이 시작됩니다.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MSG
sleep 0.3
