# 개발 시스템 템플릿

## 개요

Claude Code 개발 환경에서 **계획 수립 → 매뉴얼 참조 → 작업 수행 → 자동 품질 검사 → 전문 에이전트 투입**을 강제하는 시스템입니다.

## 수정 가능한 파일 / 수정 불필요한 파일

```
⭐ 사용자가 수정해야 하는 파일 (2곳만)
──────────────────────────────────────
.claude/hooks/config.yml              ← Hook 동작 규칙 전체
.claude/skills/dev-manual/chapters/   ← 프로젝트 매뉴얼 내용

🔒 수정하지 않아도 되는 파일 (시스템 내부)
──────────────────────────────────────
.claude/settings.json                 ← Hook 등록 (자동 설정됨)
.claude/hooks/*.sh                    ← Hook 스크립트 (config.yml이 제어)
.claude/hooks/lib/*.sh                ← 매칭 엔진 (config.yml이 제어)
.claude/skills/plan-manager/          ← 계획 3문서 생성 규칙
.claude/agents/qa-agent.md            ← 품질관리 서브에이전트
.claude/agents/test-agent.md          ← 테스트 서브에이전트
.claude/agents/planning-agent.md      ← 기획 서브에이전트
```

## 전체 구조

```
dev-system-template/
├── .claude/
│   ├── settings.json                         ← Hook 통합 설정
│   ├── hooks/
│   │   ├── config.yml                        ← ⭐ 중앙 설정 (이것만 수정)
│   │   ├── lib/
│   │   │   ├── config-parser.sh              ← YAML 파서
│   │   │   └── matcher.sh                    ← 매칭 유틸리티
│   │   ├── plan-guard.sh                     ← 계획 없이 작업 시작 방지
│   │   ├── pre-prompt-check.sh               ← 매뉴얼 리마인더
│   │   ├── change-logger.sh                  ← 변경 로그 자동 기록
│   │   ├── post-tool-check.sh                ← 품질 셀프체크
│   │   ├── checklist-tracker.sh              ← 체크리스트 업데이트 알림
│   │   ├── completion-checker.sh             ← 린트/타입 자동 검사
│   │   └── subagent-report-check.sh         ← 서브에이전트 보고서 확인
│   ├── agents/
│   │   ├── qa-agent.md                      ← [서브에이전트] 품질관리
│   │   ├── test-agent.md                    ← [서브에이전트] 테스트
│   │   └── planning-agent.md                ← [서브에이전트] 기획
│   └── skills/
│       ├── setup/                     ← [초기화 위저드] /setup 으로 실행
│       │   └── SKILL.md
│       ├── dev-manual/                       ← [시스템 1] 자동 매뉴얼
│       │   ├── SKILL.md
│       │   └── chapters/  (01~06)
│       └── plan-manager/                     ← [시스템 2] 작업 기억
│           └── SKILL.md
├── docs/
│   ├── plans/                                ← 계획 3문서 저장소
│   │   └── {작업명}/ (PLAN / CONTEXT / CHECKLIST)
│   ├── logs/                                 ← 변경 로그 자동 저장
│   │   └── change-log.md
│   └── reports/                              ← 에이전트 보고서
│       ├── qa-report-{날짜}.md
│       ├── test-report-{날짜}.md
│       └── planning-report-{날짜}.md
└── SETUP-GUIDE.md
```

---

## 전체 동작 흐름

```
사용자 지시 입력
    │
    ▼
┌─ [Hook] plan-guard ─────── 계획 있는가?
│       없음 → "계획부터 수립하세요" → /plan-manager
│       있음 → "진행 중: {작업명}" → CHECKLIST.md 확인
│
├─ [Hook] pre-prompt-check ── 매뉴얼 읽었는가?
│       → /dev-manual 스킬 → 해당 챕터만 로딩
│
▼
작업 수행 (Edit / Write / Bash)
│
├─ [Hook] change-logger ───── docs/logs/change-log.md 에 자동 기록
├─ [Hook] post-tool-check ─── 위험? 에러? 보안? 누락? 셀프체크
├─ [Hook] checklist-tracker ── CHECKLIST.md 업데이트 리마인더
│
▼
Claude 응답 완료
│
└─ [Hook] completion-checker ── 린트 & 타입 자동 검사
        │
        ├── 오류 0건 → ✅ 통과 + 셀프체크 리마인더
        ├── 오류 1~3건 → ⚠️ 즉시 수정
        └── 오류 4건+ → 🚨 전문 서브에이전트 자동 위임
                │
                ├── qa-agent       품질관리
                ├── test-agent     테스트
                └── planning-agent 기획
                        │
                        ▼
                  docs/reports/ 에 보고서 저장
                        │
                  [Hook] subagent-report-check → 보고서 작성 확인
```

---

## 시스템 1: 자동 매뉴얼

스킬: `/dev-manual`

SKILL.md에 목차만 담고, 6개 챕터를 분리하여 필요한 것만 읽는 구조. 작업 유형별로 읽을 챕터가 다르다 (새 기능 → 1,2,3 / 버그 수정 → 1,4 / API → 2,3,4,5).

## 시스템 2: 작업 기억

스킬: `/plan-manager`

코드 한 줄 쓰기 전에 3문서를 먼저 생성. 파일로 남기 때문에 세션이 끊겨도 이어서 작업 가능.

- PLAN.md → 뭘 만들 건지 (전체 그림)
- CONTEXT.md → 왜 이렇게 결정했는지 (근거)
- CHECKLIST.md → 뭘 끝냈고 뭐가 남았는지 (추적)

## 시스템 3: 자동 품질 검사

3중 검사 구조:

| 장치 | Hook | 타이밍 | 동작 |
|------|------|--------|------|
| 수정 기록 | change-logger | PostToolUse | 모든 파일 변경을 change-log.md에 누적 기록 |
| 완료 후 검사 | completion-checker | Stop | 변경된 파일에 린트/타입체크 자동 실행 |
| 셀프체크 | post-tool-check | PostToolUse | 매 수정 후 보안/에러/위험/누락 리마인더 |

오류 수에 따른 분기: 0건=통과 / 1~3건=즉시수정 / 4건+=전문에이전트

## 전문 서브에이전트

| 에이전트 | 위치 | 역할 | 산출물 |
|----------|------|------|--------|
| qa-agent | `.claude/agents/qa-agent.md` | 코드 검토, 오류 수정, 구조 개선 | qa-report-{날짜}.md |
| test-agent | `.claude/agents/test-agent.md` | 기능 테스트, 오류 진단, 화면 확인 | test-report-{날짜}.md |
| planning-agent | `.claude/agents/planning-agent.md` | 계획 수립, 계획 검토, 문서 작성 | planning-report-{날짜}.md |

서브에이전트는 `.claude/agents/` 디렉토리에 정의되며, Claude가 상황에 따라 **자동으로 위임**합니다. 각 에이전트는 독립적인 도구 세트와 모델(sonnet)을 가지며, **반드시 보고서를 작성**합니다. SubagentStop 훅이 보고서 작성 여부를 자동 검사합니다.

---

## Hook 전체 요약

| # | Hook | 이벤트 | 대상 | 역할 |
|---|------|--------|------|------|
| 1 | plan-guard | UserPromptSubmit | 전체 | 계획 존재 확인, 없으면 수립 안내 |
| 2 | pre-prompt-check | UserPromptSubmit | 전체 | 개발 매뉴얼 참조 리마인더 |
| 3 | change-logger | PostToolUse | Edit/Write/Bash | 변경 로그 자동 기록 |
| 4 | post-tool-check | PostToolUse | Edit/Write/Bash | 보안/에러/위험/누락 셀프체크 |
| 5 | checklist-tracker | PostToolUse | Edit/Write | CHECKLIST.md 업데이트 리마인더 |
| 6 | completion-checker | Stop | 전체 | 린트/타입 자동 검사 + 분기 판단 |
| 7 | subagent-report-check | SubagentStop | 전체 | 서브에이전트 보고서 작성 확인 |

---

## 매칭 조건 시스템

모든 Hook은 공통 유틸리티(`lib/matcher.sh`)를 통해 4가지 조건으로 상황을 분석합니다.

### 4가지 매칭 조건

| # | 조건 | 감지 대상 | 활용 예시 |
|---|------|-----------|-----------|
| 1 | **키워드** | 프롬프트/명령어의 특정 단어 | "수정해줘" → dev / "테스트" → test |
| 2 | **의도 파악** | 요청 패턴 분석 → 작업 유형 분류 | "새로운 API 만들어" → api → 챕터 2,3,4,5 추천 |
| 3 | **작업 위치** | 파일 경로 → 도메인/레이어 감지 | `src/api/user.ts` → api → 입력검증/인증 중점 검사 |
| 4 | **파일 내용** | 코드 패턴 → 품질 문제 감지 | eval() 사용 → [보안] 위험 함수 경고 |

### 각 Hook별 매칭 조건 활용

```
plan-guard.sh        → [1.키워드] [2.의도] [3.위치]
  키워드로 개발 지시 필터 → 의도로 계획 강제 수준 판별
  → 파일 경로로 관련 계획 자동 탐색

pre-prompt-check.sh  → [1.키워드] [2.의도] [3.위치]
  키워드로 필터 → 의도로 작업 유형 분류
  → 챕터 자동 추천 + 파일 위치로 검사 중점 안내

post-tool-check.sh   → [3.위치] [4.내용]
  파일 경로에서 레이어 감지 → 레이어별 맞춤 체크리스트
  → 파일 내용에서 패턴 감지 (eval, 하드코딩, any, 디버그 등)

completion-checker.sh → [3.위치] [4.내용]
  린트/타입 자동 검사 + 파일 내용 패턴 이중 검사
  → 위치별 검사 중점 부여
```

### 의도 → 챕터 매핑

| 감지된 의도 | 추천 챕터 |
|-------------|-----------|
| 새 기능 개발 | 1(프로젝트 개요), 2(코딩 표준), 3(아키텍처) |
| 버그 수정 | 1(프로젝트 개요), 4(에러 처리) |
| 리팩토링 | 2(코딩 표준), 3(아키텍처) |
| API 작업 | 2(코딩 표준), 3(아키텍처), 4(에러 처리), 5(보안) |
| 보안 작업 | 5(보안), 4(에러 처리) |
| 테스트 | 6(테스트) |

### 작업 위치 → 검사 중점

| 감지된 위치 | 중점 검사 항목 |
|-------------|---------------|
| ui (컴포넌트/페이지) | XSS 방지, 접근성, 상태 관리, 렌더링 성능 |
| api (라우트/컨트롤러) | 입력 검증, 인증/인가, Rate Limiting, 에러 응답 형식 |
| service (비즈니스 로직) | 에러 처리, 엣지 케이스, 타입 안전성, 단위 테스트 |
| db (모델/스키마) | SQL Injection 방지, 마이그레이션 안전성, 인덱스 |
| config (설정) | 환경변수 노출, 호환성, 기본값 |
| test (테스트) | 커버리지, 엣지 케이스, 비동기, Mock 정확성 |

### 코드 패턴 감지 항목

| 패턴 | 감지 대상 |
|------|-----------|
| [보안] 위험 함수 | eval(), innerHTML, exec(), .raw() |
| [보안] 하드코딩 비밀정보 | password=, secret=, api_key= 등 |
| [에러처리] catch 누락 | await/then 있지만 try-catch/catch 없음 |
| [타입] any 사용 | : any 타입 N건 |
| [정리] 디버그 잔류 | console.log, debugger, TODO, FIXME |

### 커스터마이징

**config.yml만 수정하면 됩니다.** 스크립트를 직접 수정할 필요 없습니다.

config.yml이 없거나 특정 항목이 비어있으면 내장 기본값으로 폴백하므로, 부분적으로만 수정해도 동작합니다.

---

## config.yml 사용법

위치: `.claude/hooks/config.yml`

이 파일 하나로 전체 시스템 동작을 제어합니다.

### 키워드 수정 예시

```yaml
# React Native 프로젝트라면:
keywords:
  dev: "만들|개발|수정|추가|삭제|컴포넌트|네비게이션|스크린|fix|create|add"
```

### 의도 추가 예시

```yaml
intents:
  # 기존 의도에 추가
  migration:
    patterns: "마이그레이션|migration|스키마 변경|DB 변경"
    label: "DB 마이그레이션"
    chapters: "1(프로젝트 개요), 3(아키텍처)"
    require_plan: true
```

### 경로 패턴 수정 예시

```yaml
locations:
  # 프로젝트 구조가 다르면 패턴 수정
  ui:
    patterns: "(screens?|features?)/.*\\.(tsx?|jsx?)"  # React Native
    label: "화면/기능"
    focus: "XSS 방지, 접근성, 상태 관리"
    checklist:
      - "화면 전환 시 상태 초기화가 되는가?"
      - "디바이스 뒤로가기 처리가 되는가?"
```

### 코드 패턴 추가 예시

```yaml
code_patterns:
  # 기존 패턴에 추가
  react_useeffect_cleanup:
    pattern: "useEffect\\("
    severity: "warning"
    message: "[React] useEffect에 cleanup 함수가 필요하지 않은가?"
```

### 오류 임계값 조정

```yaml
completion_check:
  threshold_immediate_fix: 5    # 5건까지 즉시 수정
  threshold_agent_recommend: 6  # 6건 이상 에이전트 권장
```

---

## 설치 및 초기 세팅

```bash
# 1. 프로젝트 루트에 복사
cp -r dev-system-template/.claude .claude/
cp -r dev-system-template/docs docs/

# 2. 실행 권한
chmod +x .claude/hooks/*.sh .claude/hooks/lib/*.sh

# 3. Claude Code 종료 후 재시작 (스킬 인식을 위해 필수)
/exit

# 4. 재시작 후 /setup 실행
```

> **주의:** 설치 후 반드시 `/exit`으로 Claude Code를 종료하고 다시 시작해야 합니다. 재시작해야 `/setup` 등 스킬이 인식됩니다.

### 초기 세팅 흐름 (/setup)

처음 실행하면 시스템이 자동으로 감지하고 `/setup` 실행을 안내합니다.

```
사용자: "로그인 기능 만들어줘"
    │
    ▼
🚀 [초기 세팅] 프로젝트 설정이 필요합니다
→ /setup 을 실행하여 프로젝트 초기화 위저드를 시작하세요
    │
    ▼
사용자: /setup
    │
    ▼
━━━ Phase 1: 프로젝트 비전 ━━━
  프로젝트명, 설명, 핵심 기능, 첫 작업 수집
    │ (사용자 확인)
    ▼
━━━ Phase 2: 기술 환경 ━━━
  기술 스택, 디렉토리 구조 (기존 프로젝트면 자동 분석)
    │ (사용자 확인)
    ▼
━━━ Phase 3: 워크플로우 설정 ━━━
  코딩 규칙, 에러처리, 보안, 추가 스킬/에이전트
    │ (사용자 확인)
    ▼
━━━ Phase 4: 초기 개발 계획 ━━━
  첫 번째 기능의 3문서(PLAN/CONTEXT/CHECKLIST) 생성
    │ (사용자 확인)
    ▼
━━━ Phase 5: 환경 세팅 적용 ━━━
  CLAUDE.md + config.yml + 매뉴얼 6개 + 초기화 마커
    │
    ▼
✅ 세팅 완료 → "시작해줘" 로 첫 기능 개발 시작
```

각 Phase 사이에 반드시 사용자 확인을 받으므로, 프로젝트에 딱 맞는 세팅이 됩니다.
기존 프로젝트에 적용하면 코드 자동 분석으로 더 빠르게 진행됩니다.
