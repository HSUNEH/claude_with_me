# CWM (Claude With Me)

Plan-first development workflow plugin for Claude Code.

코드 작성 전에 계획을 먼저 세우고, 변경사항을 자동 추적하며, 품질 검사를 수행하는 Claude Code 플러그인입니다.

## Installation

```bash
claude plugin add --from github:HSUNEH/cwm
```

또는 로컬에서 직접 설치:

```bash
git clone https://github.com/HSUNEH/cwm.git
claude plugin add ./cwm
```

설치 후 프로젝트에서 초기화:

```
/cwm:setupwithme
```

### What You'll See

설치 후 Claude Code 사용 중 CWM 훅이 자동으로 동작하며, 상태줄에 표시됩니다:

```
 ⠋ CWM: plan check              ← Edit/Write 전 플랜 확인 중
 ⠋ CWM: logging                 ← 변경사항 자동 기록 중
 ⠋ CWM: quality check           ← 세션 종료 시 품질 검사 중
```

CWM HUD를 설치하면 상태줄에 플랜 상태, 도구 호출 수 등을 실시간 표시합니다:

```
> /cwm:custom_command

✅ CWM HUD 설치 완료
```

```
📂 my-app | 🔀 main | ▓▓▓░░░░░░░ 28% | 🔧12 🤖2 ⚡3 | 📋 user-auth | 5h
```

| 항목 | 설명 |
|------|------|
| `📂 my-app` | 현재 작업 폴더 |
| `🔀 main` | 현재 Git 브랜치 |
| `▓▓▓░░░░░░░ 28%` | 컨텍스트 사용량 |
| `🔧12 🤖2 ⚡3` | tool / agent / skill 호출 횟수 |
| `📋 user-auth` | 현재 활성 플랜 이름 |
| `5h` | 남은 사용 한도 |

플랜 없이 3개 이상 파일을 수정하면 차단됩니다:

```
⛔ [CWM] 플랜 없이 3개 파일을 수정하려 합니다

  /cwm:planwithme {작업명}  → 플랜을 먼저 세우세요
  "간단: {요청}"            → 플랜 없이 계속 진행
```

세션 종료 시 이슈가 있으면 알려줍니다:

```
⚠️ [CWM] 2 issues found — fix directly

[ESLint] src/auth.ts:
  12:5  error  'token' is defined but never used
[Security] src/db.ts:
  8: const password = "admin123"
```

## Features

### Skills

| Command | Description |
|---------|-------------|
| `/cwm:setupwithme` | 프로젝트 초기화 위저드 (5단계) |
| `/cwm:planwithme` | 작업 전 계획 수립 (PLAN.md, CONTEXT.md, CHECKLIST.md 생성) |
| `/cwm:dev-manual` | 프로젝트별 개발 가이드 챕터 열람 |
| `/cwm:custom_command` | CWM HUD 설치 (상태줄에 플랜 상태 표시) |

### Hooks

| Hook | Event | Description |
|------|-------|-------------|
| plan-enforcer | PreToolUse | 플랜 없이 3개+ 파일 수정 시 차단 |
| change-logger | PostToolUse | 모든 변경사항 자동 기록 |
| completion-checker | Stop | 세션 종료 시 린트/타입/보안 검사 |

### Agents

| Agent | Description |
|-------|-------------|
| planning-agent | 계획 수립, 검토, 문서 작성 |
| qa-agent | 코드 검토, 오류 수정, 구조 개선 |
| test-agent | 테스트 작성, 실행, 결과 분석 |

## How It Works

```
/cwm:setupwithme          프로젝트 초기화
        │
        ▼
/cwm:planwithme {작업명}   계획 수립 → 승인 대기
        │
        ▼
    승인 → 구현               Phase별 순서대로 구현
        │
        ▼
    세션 종료                  자동 품질 검사
```

1. **Plan-first** — 코드 작성 전에 계획 수립 필수
2. **Auto-tracking** — 변경사항을 `.cwm/docs/logs/change-log.md`에 자동 기록
3. **Quality gate** — 세션 종료 시 린트/타입/보안 패턴 자동 검사
4. **Context continuity** — `.cwm/docs/plans/`의 파일 기반 상태 관리로 세션 간 이어서 작업 가능

## Project Structure (after setup)

```
your-project/
├── .cwm/
│   ├── config.yml                  Hook 동작 설정
│   ├── dev-manual/chapters/        개발 가이드 (6챕터)
│   ├── docs/
│   │   ├── plans/{작업명}/         계획 문서 (PLAN, CONTEXT, CHECKLIST, .status)
│   │   ├── logs/change-log.md     변경 이력
│   │   └── reports/               에이전트 보고서
│   ├── state/                     훅 내부 상태
│   └── .initialized               초기화 완료 마커
└── CLAUDE.md                       CWM 워크플로우 규칙
```

## Configuration

`.cwm/config.yml`에서 설정 변경 가능:

```yaml
plan_enforcer:
  threshold: 3              # 플랜 없이 수정 가능한 파일 수

completion_check:
  threshold_immediate_fix: 3 # 즉시 수정 권장 이슈 수
  threshold_agent_recommend: 4 # qa-agent 위임 권장 이슈 수
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` (hooks에서 사용, 없으면 hooks 자동 스킵)

## License

MIT
