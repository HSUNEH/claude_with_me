# CWM : Claude With Me

<p align="center">
  <img src="./assets/hero.png" alt="Claude With Me" width="600" />
</p>

<p align="center">
  Claude Code 플러그인으로 <strong>Plan-first 개발 워크플로우</strong>를 제공하는 하네스.<br/>
  큰 작업은 플랜부터, 간단한 작업은 바로 진행. Claude가 알아서 판단하고, 안전망이 잡아줍니다.
</p>

---

## 설치

### 1. 마켓플레이스 등록 (최초 1회)

```
/plugin marketplace add https://github.com/HSUNEH/claude_with_me
```

### 2. 플러그인 설치

```
/plugin install cwm
```

### 3. 프로젝트 세팅

```
/cwm:setupwithme
```

5단계 위저드가 프로젝트 비전, 기술 스택, 워크플로우를 수집하고 자동으로 환경을 구성합니다.

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
| 2 | **change-logger** | 모든 변경을 `docs/logs/change-log.md`에 무출력으로 기록 |
| 3 | **plan-enforcer** | 플랜 없이 3개+ 파일 수정 시 차단 (PreToolUse, exit 2) |

- 질문 ("수정해야할까?") → Edit 안 일어남 → 절대 차단 안 됨
- 짧은 응답 ("ㄱㄱ", "응") → Claude가 맥락으로 이해
- 큰 작업인데 플랜 안 세움 → 3파일째에서 안전망이 차단

---

## 플랜 상태 관리

이모지 파싱 대신 `.status` 파일로 안정적 관리:

```
docs/plans/{작업명}/
├── PLAN.md          # 구현 계획
├── CONTEXT.md       # 결정 근거
├── CHECKLIST.md     # 작업 추적
└── .status          # pending → active → complete
```

---

## 스킬

| 명령어 | 설명 |
|--------|------|
| `/cwm:setupwithme` | 프로젝트 초기화 5단계 위저드 |
| `/cwm:planwithme` | 3문서 + .status 생성, 승인 워크플로우 |
| `/cwm:dev-manual` | 작업 유형별 개발 매뉴얼 챕터 참조 |

---

## 서브에이전트

| 에이전트 | 역할 | 트리거 |
|----------|------|--------|
| **qa-agent** | 코드 검토, 오류 수정, 보고서 작성 | 린트 에러 4건+ |
| **test-agent** | 테스트 작성/실행, 오류 진단 | 테스트 필요 시 |
| **planning-agent** | 계획 수립/검토, 문서 작성 | 기획 필요 시 |

---

## 프로젝트 구조

```
cwm/
├── .claude-plugin/          # 플러그인 매니페스트
├── hooks/
│   ├── hooks.json           # 3개 훅 등록
│   └── scripts/
│       ├── plan-enforcer.sh # PreToolUse 안전망
│       ├── change-logger.sh # 무출력 로깅
│       └── completion-checker.sh  # 린트/타입 검사
├── skills/
│   ├── setupwithme/         # 프로젝트 초기화
│   ├── planwithme/          # 플랜 생성
│   └── dev-manual/          # 개발 매뉴얼
├── agents/                  # 서브에이전트 3개
└── templates/               # config.yml, docs 구조
```

---

## 설정

`/cwm:setupwithme` 실행 시 `.cwm/config.yml`이 프로젝트에 맞게 자동 생성됩니다.

주요 설정:

```yaml
plan_enforcer:
  threshold: 3          # 플랜 없이 허용할 최대 파일 수

general:
  require_plan: true    # 플랜 강제 글로벌 토글
```

---

## 기존 dev_sys_template에서 마이그레이션

v1.x (dev_sys_template) → v2.0 (CWM) 주요 변경:

| v1.x | v2.0 |
|------|------|
| `install.sh` + `.claude/` 직접 설치 | `/plugin install cwm` |
| `/setup` | `/cwm:setupwithme` |
| `/plan-manager` | `/cwm:planwithme` |
| 7개 훅 (매 Edit마다 30-50줄 출력) | **3개 훅** (무출력 or 차단 시에만) |
| 이모지 파싱 (`🟡 진행 중`) | `.status` 파일 (`active`) |
| 프롬프트 텍스트 분석 (오탐 위험) | **행위 기반** (Edit 횟수) 판단 |
| `exit 0` 만 (차단 없음) | `exit 2` 실제 차단 |

---

## 로드맵

- **v2.0** (현재): 플러그인 전환, 3계층 시스템, .status 파일
- **v2.1**: strict mode 옵트인, 큐 시스템 기초
- **v3.0**: 플랜 큐 (여러 플랜 순차 실행), Node.js 재작성, MCP 서버

---

## 라이선스

MIT
