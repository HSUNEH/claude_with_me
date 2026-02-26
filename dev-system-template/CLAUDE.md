# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 이 저장소가 하는 일

Claude Code 개발 환경에서 **계획 수립 → 매뉴얼 참조 → 작업 수행 → 자동 품질 검사 → 전문 에이전트 투입**을 강제하는 개발 시스템 템플릿이다. 프로젝트에 `.claude/`와 `docs/`를 복사하여 적용한다.

## 처음 사용 시 — 반드시 `/setup` 먼저

이 시스템을 새 프로젝트에 적용한 직후에는 **반드시 `/setup`을 먼저 실행**해야 한다.
`/setup`은 5단계 대화형 위저드로 프로젝트 전체 세팅을 완료한다:

```
/setup 실행 → 프로젝트 비전 수집 → 기술 환경 분석 → 워크플로우 설정
         → 초기 개발 계획 수립 → 환경 세팅 자동 적용
```

**`/setup` 완료 후 이 CLAUDE.md는 프로젝트 전용 내용으로 자동 교체된다.**

`.claude/.initialized` 마커가 없으면 아직 초기 세팅이 안 된 것이다.

## 컨텍스트 관리 규칙

- **계획 → 구현 전환 시**: 대화 히스토리에 의존하지 않는다. 반드시 `docs/plans/{작업명}/`의 PLAN.md, CHECKLIST.md를 **파일에서 다시 읽고**, 현재 Phase와 남은 작업을 파악한 뒤 구현을 시작한다.
- **매 작업 시작 시**: CHECKLIST.md에서 현재 진행할 Phase의 세부 작업만 집중한다. 전체 계획을 한꺼번에 처리하지 않고, Phase 단위로 나눠서 진행한다.
- **새 세션에서 이어서 작업할 때**: `docs/plans/`에서 `🟡 진행 중`인 CHECKLIST.md를 찾아 읽고, 체크된 항목은 건너뛰고 미체크 항목부터 이어서 진행한다.

## 절대 금지 규칙

- **사용자가 계획을 승인하기 전에 코드를 작성하지 않는다.** 계획서(PLAN.md)를 생성한 뒤 반드시 사용자에게 보여주고, 사용자가 "확인", "승인", "진행", "ㅇㅇ", "좋아" 등 명시적으로 동의할 때까지 기다린다.
- **CHECKLIST.md 상태가 `🔴 시작 전`이면 아직 승인되지 않은 것이다.** 사용자 승인 후에만 `🟡 진행 중`으로 변경하고 구현을 시작한다.
- **한 턴에 계획과 구현을 동시에 하지 않는다.** 계획 수립과 코드 작성은 반드시 별도의 턴에서 수행한다.

## 필수 워크플로우

모든 개발 작업은 다음 순서를 **반드시** 따른다. 단계를 건너뛰거나 합치지 않는다:

1. **계획 수립**: `/plan-manager`로 3문서(PLAN.md, CONTEXT.md, CHECKLIST.md) 생성 → `docs/plans/{작업명}/`에 저장
2. **⏸️ 승인 대기**: 계획 요약을 사용자에게 보여주고 **반드시 사용자 응답을 기다린다**. 이 단계에서 코드를 작성하거나 파일을 수정하지 않는다. 사용자가 승인하면 CHECKLIST.md를 `🟡 진행 중`으로 변경한다.
3. **매뉴얼 참조**: `/dev-manual`로 작업 유형에 맞는 챕터만 선택적으로 읽음
4. **작업 수행**: 계획서의 Phase 순서대로 구현. Hook이 변경 로그 기록, 셀프체크, 체크리스트 추적을 자동으로 수행
5. **완료 검사**: Stop Hook이 린트/타입/코드 패턴 검사 후 오류 수에 따라 분기 (0건=통과, 1~3건=즉시수정, 4건+=서브에이전트 자동 위임)

## 아키텍처

### Hook 시스템 (`.claude/hooks/`)

모든 Hook은 `config.yml` 하나로 동작을 제어한다. 스크립트를 직접 수정할 필요 없다.

- **plan-guard.sh** (UserPromptSubmit): 계획 없이 작업 시작 방지. `require_plan: true`인 의도만 강제
- **pre-prompt-check.sh** (UserPromptSubmit): 작업 유형에 맞는 매뉴얼 챕터 자동 추천
- **change-logger.sh** (PostToolUse: Edit/Write/Bash): `docs/logs/change-log.md`에 변경 자동 기록
- **post-tool-check.sh** (PostToolUse: Edit/Write/Bash): 파일 위치별 맞춤 체크리스트 + 코드 패턴 감지
- **checklist-tracker.sh** (PostToolUse: Edit/Write): CHECKLIST.md 업데이트 리마인더
- **completion-checker.sh** (Stop): 변경 파일에 ESLint/tsc/py_compile 실행 + 코드 패턴 이중 검사
- **subagent-report-check.sh** (SubagentStop): 서브에이전트 보고서 작성 여부 확인

### 매칭 엔진 (`lib/matcher.sh`, `lib/config-parser.sh`)

4가지 조건으로 상황을 분석한다:
1. **키워드**: 프롬프트에서 dev/test/deploy/docs 분류
2. **의도 파악**: 패턴 매칭으로 작업 유형(new_feature, bugfix, refactor, api, security, test, docs) 자동 분류 → 챕터 추천
3. **작업 위치**: 파일 경로에서 도메인(ui, api, service, db, config, test, style) 감지 → 맞춤 체크리스트
4. **파일 내용**: eval/innerHTML, 하드코딩 비밀정보, catch 누락, any 타입, 디버그 잔류 패턴 감지

### 서브에이전트 (`.claude/agents/`)

모두 sonnet 모델 사용. 반드시 `docs/reports/`에 보고서 작성.
- **qa-agent**: 코드 검토, 오류 수정, 구조 개선
- **test-agent**: 기능 테스트, 오류 진단, 테스트 작성
- **planning-agent**: 계획 수립/검토, 문서 작성 (코드 수정 불가, Read/Grep/Glob/Write만 사용)

### 스킬 (`.claude/skills/`)

- `/setup`: 프로젝트 초기화 위저드. 5단계 대화로 비전 수집 → 환경 분석 → 워크플로우 설정 → 초기 계획 → 환경 세팅
- `/dev-manual`: 6개 챕터(프로젝트개요/코딩표준/아키텍처/에러처리/보안/테스트)를 필요한 것만 선택적으로 읽음
- `/plan-manager`: 코드 작성 전 3문서(PLAN/CONTEXT/CHECKLIST) 생성. kebab-case 폴더명 사용

## 수정 가능한 파일

- `.claude/hooks/config.yml` — Hook 동작 규칙 전체 (키워드, 의도, 경로 패턴, 코드 패턴, 임계값 등)
- `.claude/skills/dev-manual/chapters/` — 프로젝트별 매뉴얼 내용 (01~06)

그 외 `.claude/` 내부 파일(settings.json, *.sh, agents/, skills/plan-manager/, skills/setup/)은 시스템 내부 파일로 수정 불필요.

## 설치

```bash
cp -r dev-system-template/.claude .claude/
cp -r dev-system-template/docs docs/
chmod +x .claude/hooks/*.sh .claude/hooks/lib/*.sh
```

설치 후 `/setup`을 실행하여 프로젝트 세팅을 완료한다.
