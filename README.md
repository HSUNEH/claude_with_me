# CWM (Claude With Me)

<p align="center">
  <img src="./assets/hero.png" alt="Claude With Me" width="600" />
</p>

<p align="center">
  Claude Code 플러그인으로 <strong>Plan-first 개발 워크플로우</strong>를 제공하는 하네스.<br/>
  큰 작업은 플랜부터, 간단한 작업은 바로 진행. Claude가 알아서 판단하고, 안전망이 잡아줍니다.
</p>

---

## Installation

### 1. 마켓플레이스 등록 (최초 1회)

```
/plugin marketplace add https://github.com/HSUNEH/claude_with_me
```

### 2. 플러그인 설치

```
/plugin install cwm
```

### 3. 프로젝트 초기화

```
/cwm:setupwithme
```

5단계 위저드로 `.cwm/config.yml`, 개발 매뉴얼, `CLAUDE.md`, 초기 플랜을 생성합니다.

### 4. HUD 설치 (선택)

```
/cwm:custom_command
```

상태줄에 CWM 전용 HUD를 표시합니다:

```
📂 my-app | 🔀 main | ▓▓▓░░░░░░░ 28% | 🔧12 🤖2 ⚡3 | 📋 user-auth | ██░ 26m:65%
```

| 항목 | 설명 |
|------|------|
| `📂 my-app` | 현재 작업 폴더 |
| `🔀 main` | Git 브랜치 |
| `▓▓▓░░░░░░░ 28%` | 컨텍스트 사용량 |
| `🔧12 🤖2 ⚡3` | tool / agent / skill 호출 횟수 |
| `📋 user-auth` | 현재 활성 플랜 이름 (.cwm/docs/plans/ 기반) |
| `██░ 26m:65%` | 5h 리밋 (남은 시간 : 사용 퍼센티지) |

### What You'll See

설치 후 Claude Code 사용 중 CWM 훅이 자동으로 동작하며, 상태줄에 표시됩니다:

```
 ⠋ CWM: plan check              ← Edit/Write 전 플랜 확인 중
 ⠋ CWM: logging                 ← 변경사항 자동 기록 중
 ⠋ CWM: quality check           ← 세션 종료 시 품질 검사 중
```

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

---

## 사용법

### 간단한 작업

그냥 요청하세요. Claude가 판단해서 바로 진행합니다.

```
> 이 변수 이름 바꿔줘
→ (1-2파일 수정, 바로 진행)
```

### 큰 작업

Claude가 먼저 물어봅니다. 또는 직접 플랜을 세울 수 있습니다.

```
> /cwm:planwithme 로그인-기능
→ PLAN.md, CONTEXT.md, CHECKLIST.md 생성
→ 승인 → /clear → 구현 시작
```

### 명시적 우회

```
> 간단: 로고 이미지 교체해줘
→ 플랜 없이 즉시 진행
```

---

## 3계층 강제 시스템

| 계층 | 메커니즘 | 역할 |
|:---:|----------|------|
| 1 | **CLAUDE.md 규칙** | Claude가 큰 작업 전 자발적으로 "플랜 세울까요?" 물어봄 |
| 2 | **change-logger** | 모든 변경을 `.cwm/docs/logs/change-log.md`에 무출력으로 기록 |
| 3 | **plan-enforcer** | 플랜 없이 3개+ 파일 수정 시 차단 (PreToolUse, exit 2) |

> 모든 훅은 `/cwm:setupwithme`로 초기화된 프로젝트에서만 동작합니다.

---

## 플랜 상태 관리

`.status` 파일로 안정적 관리:

```
.cwm/docs/plans/{작업명}/
├── PLAN.md          # 구현 계획
├── CONTEXT.md       # 결정 근거
├── CHECKLIST.md     # 작업 추적
└── .status          # pending → active → complete
```

---

## Features

### Skills

| 명령어 | 설명 |
|--------|------|
| `/cwm:setupwithme` | 프로젝트 초기화 5단계 위저드 |
| `/cwm:planwithme` | 3문서 + .status 생성, 승인 워크플로우 |
| `/cwm:dev-manual` | 작업 유형별 개발 매뉴얼 챕터 참조 |
| `/cwm:custom_command` | CWM HUD 설치 (상태줄에 플랜 상태 표시) |

### Hooks

| Hook | Event | Description |
|------|-------|-------------|
| plan-enforcer | PreToolUse | 플랜 없이 3개+ 파일 수정 시 차단 |
| change-logger | PostToolUse | 모든 변경사항 자동 기록 |
| completion-checker | Stop | 세션 종료 시 린트/타입/보안 검사 |

### Agents

| 에이전트 | 역할 | 트리거 |
|----------|------|--------|
| **qa-agent** | 코드 검토, 오류 수정, 보고서 작성 | 린트 에러 4건+ |
| **test-agent** | 테스트 작성/실행, 오류 진단 | 테스트 필요 시 |
| **planning-agent** | 계획 수립/검토, 문서 작성 | 기획 필요 시 |

---

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

---

## Configuration

`.cwm/config.yml`에서 설정 변경 가능:

```yaml
plan_enforcer:
  threshold: 3              # 플랜 없이 수정 가능한 파일 수

completion_check:
  threshold_immediate_fix: 3 # 즉시 수정 권장 이슈 수
  threshold_agent_recommend: 4 # qa-agent 위임 권장 이슈 수

general:
  require_plan: true         # 플랜 강제 글로벌 토글
```

---

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `jq` (hooks에서 사용, 없으면 hooks 자동 스킵)

---

## License

MIT
