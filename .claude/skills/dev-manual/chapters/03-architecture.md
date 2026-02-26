# 챕터 3: 아키텍처

## 전체 흐름

```
사용자 프롬프트
    │
    ▼
[UserPromptSubmit Hooks]
    ├── plan-guard.sh        ← 계획 강제
    └── pre-prompt-check.sh  ← 매뉴얼 추천
    │
    ▼
[Claude Code 작업 수행]
    │
    ▼
[PostToolUse Hooks]
    ├── change-logger.sh      ← 변경 기록
    ├── post-tool-check.sh    ← 품질 셀프체크
    └── checklist-tracker.sh  ← 체크리스트 리마인더
    │
    ▼
[Stop Hook]
    └── completion-checker.sh ← 린트/타입 검사 + 에이전트 분기
    │
    ▼
[SubagentStop Hook]
    └── subagent-report-check.sh ← 보고서 확인
```

## 핵심 모듈

### 매칭 엔진 (`lib/matcher.sh`, `lib/config-parser.sh`)

모든 Hook의 핵심. 4가지 조건으로 상황 분석:

| 조건 | 함수 | 용도 |
|------|------|------|
| 키워드 | `match_keywords()` | 프롬프트 → dev/test/deploy/docs 분류 |
| 의도 | `detect_intent()` | 패턴 → 작업 유형 분류 → 챕터 추천 |
| 위치 | `detect_location()` | 파일 경로 → 도메인 감지 |
| 내용 | `check_code_patterns()` | 코드 패턴 → 품질 문제 감지 |

### 설정 파서 (`lib/config-parser.sh`)

- `cfg_get()`: config.yml에서 값 읽기
- `cfg_get_list()`: 리스트 항목 읽기
- config.yml 없으면 내장 기본값으로 폴백

## 의존성 방향

```
config.yml
    ↓ (읽기)
config-parser.sh
    ↓ (사용)
matcher.sh
    ↓ (사용)
각 Hook 스크립트
```

**규칙**: Hook → lib 방향만 허용. lib 간 순환 의존 금지.

## 스킬 구조

| 스킬 | 파일 | 역할 |
|------|------|------|
| /setup | `skills/setup/SKILL.md` | 5단계 초기화 위저드 |
| /plan-manager | `skills/plan-manager/SKILL.md` | 3문서 생성 |
| /dev-manual | `skills/dev-manual/SKILL.md` + `chapters/` | 매뉴얼 선택적 읽기 |

## 서브에이전트

모두 sonnet 모델. `docs/reports/`에 보고서 필수.

| 에이전트 | 도구 | 역할 |
|----------|------|------|
| qa-agent | Read, Grep, Glob, Edit, Write, Bash | 코드 검토/수정 |
| test-agent | Read, Grep, Glob, Edit, Write, Bash | 테스트 작성/실행 |
| planning-agent | Read, Grep, Glob, Write | 계획/문서만 (코드 수정 불가) |
