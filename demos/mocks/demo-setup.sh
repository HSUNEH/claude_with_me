#!/usr/bin/env bash
# demo-setup.sh — /setup 위저드 5단계 출력 시뮬레이션
# Usage: bash demo-setup.sh

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

type_text() {
    local text="$1"
    local delay="${2:-0.05}"
    for (( i=0; i<${#text}; i++ )); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
}

clear

# ── /setup 입력 ──
echo ""
printf "${BOLD}${CYAN}❯${RESET} ${BOLD}${WHITE}"
type_text "/setup" 0.08
printf "${RESET}"
sleep 0.5
echo ""
sleep 0.8

# ── Phase 1 시작 배너 ──
cat <<'MSG'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 프로젝트 초기화 위저드를 시작합니다
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5단계를 거쳐 개발 환경을 완벽하게 세팅합니다:

MSG

printf "  ${BOLD}Phase 1${RESET}  프로젝트 비전        ${YELLOW}← 지금${RESET}\n"
printf "  ${DIM}Phase 2  기술 환경${RESET}\n"
printf "  ${DIM}Phase 3  워크플로우 설정${RESET}\n"
printf "  ${DIM}Phase 4  초기 개발 계획${RESET}\n"
printf "  ${DIM}Phase 5  환경 세팅 적용${RESET}\n"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 1.5

# ── Phase 1 질문 ──
echo ""
printf "${BOLD}📋 Phase 1: 프로젝트에 대해 알려주세요${RESET}\n"
echo ""
sleep 0.3

QUESTIONS=(
    '1. 프로젝트 이름은 무엇인가요?'
    '2. 이 프로젝트를 한 문장으로 설명하면?'
    '3. 현재 상태는? (아이디어 단계 / 기존 프로젝트)'
    '4. 핵심 기능을 3~5개 나열해주세요'
    '5. 첫 번째로 만들고 싶은 기능은?'
)

for q in "${QUESTIONS[@]}"; do
    echo "$q"
    sleep 0.15
done

sleep 1.0

# ── 사용자 응답 시뮬레이션 ──
echo ""
printf "${GRAY}사용자 응답:${RESET}\n"
sleep 0.3

ANSWERS=(
    "이름: todo-app"
    "설명: 팀 협업용 할 일 관리 웹앱"
    "상태: 아이디어 단계"
    "기능: 사용자 인증, 할 일 CRUD, 실시간 동기화, 대시보드"
    "첫 기능: 사용자 인증"
)

for a in "${ANSWERS[@]}"; do
    printf "  ${CYAN}→${RESET} %s\n" "$a"
    sleep 0.2
done

sleep 0.8

# ── Phase 1 확인 ──
echo ""
cat <<'MSG'
📌 프로젝트 비전 확인:

  이름:       todo-app
  설명:       팀 협업용 할 일 관리 웹앱
  상태:       신규 (아이디어 단계)
  핵심 기능:   사용자 인증, 할 일 CRUD, 실시간 동기화, 대시보드
  첫 작업:     사용자 인증

이대로 진행할까요?
MSG

sleep 1.2

# ── Phase 2 ──
echo ""
printf "${BOLD}📋 Phase 2: 기술 환경을 알려주세요${RESET}\n"
sleep 0.5

echo ""
printf "  ${CYAN}→${RESET} 언어: TypeScript\n"
sleep 0.15
printf "  ${CYAN}→${RESET} 프레임워크: Next.js (App Router)\n"
sleep 0.15
printf "  ${CYAN}→${RESET} DB: PostgreSQL + Prisma\n"
sleep 0.15
printf "  ${CYAN}→${RESET} 패키지 매니저: pnpm\n"
sleep 0.15
printf "  ${CYAN}→${RESET} 테스트: Vitest\n"
sleep 0.15
printf "  ${CYAN}→${RESET} 린터: ESLint + Prettier\n"
sleep 0.8

echo ""
echo "📌 기술 환경 확인 ✓"
sleep 0.8

# ── Phase 3 ──
echo ""
printf "${BOLD}📋 Phase 3: 워크플로우 설정${RESET}\n"
sleep 0.4

echo ""
printf "  ${CYAN}→${RESET} 네이밍: camelCase (기본)\n"
sleep 0.1
printf "  ${CYAN}→${RESET} 에러 처리: 커스텀 에러 클래스\n"
sleep 0.1
printf "  ${CYAN}→${RESET} 인증: JWT\n"
sleep 0.1
printf "  ${CYAN}→${RESET} 브랜치: GitHub Flow\n"
sleep 0.6

echo ""
echo "📌 워크플로우 설정 확인 ✓"
sleep 0.8

# ── Phase 4 ──
echo ""
printf "${BOLD}📋 Phase 4: 초기 개발 계획${RESET}\n"
sleep 0.5

cat <<'MSG'

📂 docs/plans/user-auth/
  ├── PLAN.md       ← 전체 구현 계획
  ├── CONTEXT.md    ← 결정 근거 & 참조 자료
  └── CHECKLIST.md  ← 작업 체크리스트

[계획 요약]
  Phase 1: 인증 스키마 & API 설계
  Phase 2: 로그인/회원가입 UI
  Phase 3: JWT 미들웨어 & 보호 라우트
  Phase 4: 테스트 & 에러 처리

MSG
sleep 1.0

# ── Phase 5 완료 ──
echo ""
cat <<MSG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${BOLD}✅ 프로젝트 초기화 완료!${RESET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 생성된 폴더:
  todo-app/                              ← 프로젝트 코드 폴더

📄 생성된 파일:
  CLAUDE.md                              ← 프로젝트 전용 설정
  .claude/hooks/config.yml               ← Hook 동작 규칙
  .claude/skills/dev-manual/chapters/
    01-project-overview.md               ← 프로젝트 개요
    02-coding-standards.md               ← 코딩 표준
    03-architecture.md                   ← 아키텍처
    04-error-handling.md                 ← 에러 처리
    05-security.md                       ← 보안
    06-testing.md                        ← 테스트
  docs/plans/user-auth/
    PLAN.md                              ← 초기 개발 계획
    CONTEXT.md                           ← 맥락 노트
    CHECKLIST.md                         ← 체크리스트

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 /clear 를 실행하여 대화를 초기화한 뒤 작업을 시작하세요.

📋 다음 단계:
  첫 번째 기능 "사용자 인증" 의 개발 계획이 준비되어 있습니다.
  "시작해줘" 라고 하면 계획서 순서대로 개발이 시작됩니다.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MSG
echo ""
sleep 1.5
