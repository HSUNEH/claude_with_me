---
name: setupwithme
description: "CWM 프로젝트 초기화 위저드. 프로젝트 비전 수집 → 기술 환경 분석 → 워크플로우 설정 → 초기 개발 계획 수립 → 환경 세팅까지 5단계로 완료한다."
user-invocable: true
---

# CWM 프로젝트 초기화 위저드

> **`/cwm:setupwithme` 하나로 프로젝트 개발 환경을 세팅한다.**
> 5단계 대화형 위저드. 각 단계마다 사용자 확인 후 다음으로 진행.

---

## 핵심 원칙

1. **단계별 진행** — Phase 질문 답변을 받은 후에만 다음 Phase로
2. **한 번에 쏟아붓지 않기** — Phase별로 끊어서 질문
3. **기존 코드 자동 분석** — 질문 전에 감지 가능한 건 먼저 분석
4. **매 단계 사용자 확인** — "이렇게 진행할까요?" 후 다음 단계

---

## Phase 1: 프로젝트 비전 수집

### 시작 메시지

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 CWM 프로젝트 초기화를 시작합니다
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5단계를 거쳐 개발 환경을 세팅합니다:

  Phase 1  프로젝트 비전        ← 지금
  Phase 2  기술 환경
  Phase 3  워크플로우 설정
  Phase 4  초기 개발 계획
  Phase 5  환경 세팅 적용

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 질문

```
📋 Phase 1: 프로젝트에 대해 알려주세요

1. 프로젝트 이름은?
2. 한 문장으로 설명하면?
3. 현재 상태는? (아이디어 단계 / 기존 프로젝트에 적용)
4. 핵심 기능 3~5개
5. 첫 번째로 만들고 싶은 기능은?
```

답변 정리 후 확인. **⛔ 확인 전 다음 Phase로 넘어가지 않는다.**

---

## Phase 2: 기술 환경 분석

### 기존 프로젝트: 자동 분석 먼저

```
분석 대상:
├── package.json / pyproject.toml / go.mod    → 기술 스택
├── 디렉토리 구조                               → 레이아웃
├── .eslintrc / prettier / biome.json          → 린터
├── tsconfig.json                               → 언어 설정
├── 테스트 파일                                  → 테스트 프레임워크
├── Dockerfile                                  → 배포 환경
└── 기존 코드 샘플                               → 네이밍/패턴 추론
```

### 신규 프로젝트: 수동 수집

```
📋 Phase 2: 기술 환경

1. 언어: (TypeScript / JavaScript / Python / Go / 기타)
2. 프레임워크: (Next.js / React / FastAPI / Express / 기타)
3. DB: (PostgreSQL / MongoDB / MySQL / SQLite / 없음)
4. 패키지 매니저: (npm / yarn / pnpm / pip / poetry)
5. 테스트: (Jest / Vitest / Pytest / 없음)
6. 린터: (ESLint+Prettier / Biome / Ruff / 없음)
```

**⛔ 확인 후 다음 Phase.**

---

## Phase 3: 워크플로우 설정

```
📋 Phase 3: 개발 워크플로우

특별한 규칙이 있는 것만 답해주세요. 없으면 "기본".

[코딩 규칙]
1. 네이밍: (camelCase / snake_case / 기본)
2. import 순서: (특별한 규칙 있으면)
3. 코딩 컨벤션: (있으면 설명)

[에러 처리 & 보안]
4. 에러 처리 패턴: (커스텀 에러 / Result 패턴 / 기본)
5. 인증 방식: (JWT / Session / OAuth / 없음)

[프로세스]
6. Git 브랜치 전략: (GitHub Flow / trunk-based / 기본)
7. plan-enforcer 임계값: (기본 3파일 / 원하는 숫자)
```

**⛔ 확인 후 다음 Phase.**

---

## Phase 4: 초기 개발 계획

Phase 1의 "첫 번째 기능"으로 3문서 생성:

```
.cwm/docs/plans/{기능명-kebab-case}/
├── PLAN.md          계획서
├── CONTEXT.md       맥락 노트
├── CHECKLIST.md     체크리스트
└── .status          "pending"
```

사용자에게 계획 요약을 보여주고 검토 요청.
**⛔ 승인 전 Phase 5로 넘어가지 않는다. 이 승인은 계획 내용에 대한 승인이지 구현 시작이 아니다.**

---

## Phase 5: 환경 세팅 적용

수집한 정보로 다음 파일들을 자동 생성:

### 5-A: .cwm/config.yml

프로젝트에 맞게 커스터마이징:
- keywords: 기술 스택 키워드 추가
- intents: 프로젝트 특성에 맞는 의도
- locations: 실제 디렉토리 구조 반영
- code_patterns: 기술 스택에 맞는 패턴
- plan_enforcer.threshold: Phase 3에서 설정한 값

### 5-B: 매뉴얼 챕터 (6개)

`.cwm/dev-manual/chapters/01~06.md` 생성:

| 챕터 | 사용 정보 |
|------|-----------|
| 01 project-overview | Phase 1 + Phase 2 |
| 02 coding-standards | Phase 3 + Phase 2 |
| 03 architecture | Phase 2 + Phase 1 |
| 04 error-handling | Phase 3 + Phase 2 |
| 05 security | Phase 3 + Phase 2 |
| 06 testing | Phase 2 + Phase 3 |

작성 규칙:
- 구체적으로 (코드 예시 포함)
- DO / DON'T 예시
- 프로젝트 기술 스택에 맞는 실제 코드

### 5-C: CLAUDE.md 생성

**반드시** 아래 템플릿 기반으로 프로젝트 루트에 생성:

````markdown
# CLAUDE.md

## 이 프로젝트

- **이름**: {프로젝트명}
- **설명**: {한 줄 설명}
- **기술 스택**: {스택}
- **패키지 매니저**: {매니저}

## CWM 작업 규칙

1. **활성 플랜(🟡)이 없을 때 코드를 수정하기 전에 반드시 사용자에게 확인**
   - 간단한 작업 → "바로 진행할게요" 확인 후 진행
   - 큰 작업 → "/cwm:planwithme 로 플랜을 세울까요?" 제안
2. **"간단:", "바로:" 접두어 → 확인 없이 즉시 진행**
3. **활성 플랜이 있으면 → PLAN.md/CHECKLIST.md 따라 진행**
4. **한 턴에 계획과 구현을 동시에 하지 않는다**

## 디렉토리 규칙

- **프로젝트 루트**: `.cwm/.initialized` 파일이 존재하는 디렉토리. 모든 CWM 파일 경로는 이 위치 기준의 절대 경로를 사용한다.
- **`cd` 금지**: Bash로 `cd`를 사용한 경우(git 작업 등) 반드시 프로젝트 루트로 돌아온다. 또는 절대 경로만 사용하여 CWD 변경 없이 작업한다.
- **파일 생성 시 절대 경로 필수**: `.cwm/docs/plans/...` 같은 상대 경로 대신 `/full/path/to/project/.cwm/docs/plans/...` 형태로 사용한다.

## 컨텍스트 관리

- **계획 → 구현 전환 시**: `{프로젝트 루트}/.cwm/docs/plans/{작업명}/`의 PLAN.md, CHECKLIST.md를 파일에서 다시 읽고 시작
- **새 세션 또는 /clear 후 이어서**: 먼저 `.cwm/.initialized`로 프로젝트 루트를 찾고, `.cwm/docs/plans/` 아래에서 .status가 "active"인 플랜을 찾아 CHECKLIST.md의 미체크 항목부터 이어서 진행

## 필수 워크플로우

1. `/cwm:planwithme`로 3문서 생성
2. 사용자 승인 대기 → .status를 "active"로 변경
3. `/cwm:dev-manual`로 관련 챕터 참조
4. Phase 순서대로 구현, CHECKLIST.md 실시간 업데이트
5. 완료 시 .status를 "complete"로 변경

## 서브에이전트

- **qa-agent**: 코드 검토, 오류 수정, 구조 개선
- **test-agent**: 기능 테스트, 오류 진단, 테스트 작성
- **planning-agent**: 계획 수립/검토, 문서 작성
````

### 5-D: docs/ 디렉토리 구조

```bash
mkdir -p {프로젝트 루트}/.cwm/docs/plans {프로젝트 루트}/.cwm/docs/logs {프로젝트 루트}/.cwm/docs/reports
```

### 5-E: 완료 마커

```bash
touch {프로젝트 루트}/.cwm/.initialized
```

### 완료 메시지

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ CWM 세팅 완료!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

생성된 파일:
  .cwm/config.yml          ← Hook 설정
  .cwm/dev-manual/chapters/ ← 개발 매뉴얼 6챕터
  CLAUDE.md                ← 프로젝트 규칙
  .cwm/docs/plans/{첫기능}/ ← 초기 개발 계획 (🔴 대기)

다음 단계:
  1. 초기 계획을 승인하면 구현을 시작합니다
  2. 새 작업은 /cwm:planwithme 로 플랜을 먼저 세우세요
  3. /cwm:dev-manual 로 개발 매뉴얼을 참조하세요

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 중요 규칙

1. **Phase 5를 건너뛰지 않는다** — .initialized 마커 전에 코드 작성 금지
2. **"기본"으로 답한 항목은 기술 스택 관례 적용**
3. **기존 프로젝트면 자동 분석 먼저, 질문은 최소화**
