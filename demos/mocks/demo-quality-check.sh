#!/usr/bin/env bash
# demo-quality-check.sh — completion-checker 품질 검사 시뮬레이션
# Usage: bash demo-quality-check.sh

set -euo pipefail

# ── ANSI Colors ──
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'
WHITE='\033[97m'
GRAY='\033[90m'
RESET='\033[0m'

clear

# ── Claude가 작업 완료 후 응답 ──
echo ""
printf "${BOLD}${WHITE}src/api/auth.ts 파일을 수정했습니다.${RESET}\n"
sleep 0.5
echo ""

# ── 코드 변경 내용 시뮬레이션 ──
printf "${GRAY}// src/api/auth.ts (변경된 코드)${RESET}\n"
echo ""
printf "${GREEN}+${RESET} const token = eval(userInput);\n"
sleep 0.1
printf "${GREEN}+${RESET} const data = JSON.parse(body);\n"
sleep 0.1
printf "${GREEN}+${RESET} db.query(\`SELECT * FROM users WHERE id = \${id}\`);\n"
sleep 0.1
printf "${GREEN}+${RESET} res.send(userData);\n"
sleep 0.8
echo ""

# ── completion-checker Hook 실행 ──
printf "${DIM}── Stop Hook: completion-checker 실행 중... ──${RESET}\n"
sleep 1.0
echo ""

# ── 린트 검사 ──
printf "  ${YELLOW}⚡${RESET} ESLint 검사...\n"
sleep 0.4
printf "    ${RED}✗${RESET} src/api/auth.ts:12 — no-eval: eval() 사용 금지\n"
sleep 0.2
printf "    ${RED}✗${RESET} src/api/auth.ts:15 — no-template-literal-in-query\n"
sleep 0.4

# ── 코드 패턴 검사 ──
printf "  ${YELLOW}⚡${RESET} 코드 패턴 검사...\n"
sleep 0.4
printf "    ${RED}✗${RESET} eval() 사용 감지 — 보안 위험 (RCE)\n"
sleep 0.2
printf "    ${RED}✗${RESET} SQL 템플릿 리터럴 — SQL Injection 위험\n"
sleep 0.2
printf "    ${YELLOW}⚠${RESET} try-catch 누락 — JSON.parse 에러 처리 없음\n"
sleep 0.2
printf "    ${YELLOW}⚠${RESET} 응답 데이터 직접 노출 — 민감 정보 누출 가능\n"
sleep 0.8

echo ""

# ── 검사 결과 출력 ──
cat <<'MSG'
───────────────────────────────────────────
🚨 [완료 후 검사] 이슈 4건 — 전문 에이전트 권장
───────────────────────────────────────────
MSG

printf "  ${RED}에러  2건${RESET}: eval() 사용, SQL Injection\n"
printf "  ${YELLOW}경고  2건${RESET}: try-catch 누락, 데이터 노출\n"
echo ""

cat <<'MSG'
오류가 많습니다. 전문 서브에이전트 호출을 권장합니다:

  qa-agent       → 코드 검토 & 오류 수정 & 구조 개선
  test-agent     → 기능 테스트 & 오류 진단
  planning-agent → 계획 재검토 & 문서 작성

서브에이전트가 자동 위임되어 보고서를 작성합니다.
───────────────────────────────────────────
MSG
echo ""
sleep 1.5
