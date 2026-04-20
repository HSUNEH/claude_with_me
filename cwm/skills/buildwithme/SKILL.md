---
name: buildwithme
description: "활성 플랜의 Phase를 build-runner 에이전트에 위임해 구현+테스트를 일괄 수행. 사용자는 Phase별 요약만 받고 메인 컨텍스트는 깨끗하게 유지. .cwm/config.yml의 build 명령 우선, 없으면 프로젝트 매니페스트 추론."
user-invocable: true
argument-hint: (없음 — 활성 플랜 자동 감지)
---

# CWM 구현 + 테스트

> plan → build 의 후반부. **활성 플랜을 Phase 단위로 build-runner 에이전트에 위임**해 구현·테스트·재시도를 일괄 수행한다. 사용자에게는 Phase 결과 요약만 보고.

## 전제

1. `.status=active` 플랜이 **반드시** 존재해야 한다
2. 없거나 pending이면 거부: "/cwm:planwithme 먼저 실행·승인해주세요"
3. 사용자가 /cwm:buildwithme를 쓴다는 건 **"메인에서 일일이 보지 않고 위임"** 의사표시 — 그래서 agent 풀 위임 방식

## 실행 흐름 (오케스트레이션만)

```
1. 프로젝트 루트 결정 (.cwm/.initialized)
       │
       ▼
2. 활성 플랜 찾기 (.cwm/docs/plans/*/.status == "active")
   없음 → 안내 후 종료
       │
       ▼
3. 테스트/린트 명령 결정
   a. .cwm/config.yml의 build.test_cmd / build.lint_cmd
   b. 없으면 프로젝트 매니페스트 추론
   c. 추론 실패 → 사용자에게 질문 + config에 저장
       │
       ▼
4. CHECKLIST 미완료 Phase 목록 파싱
       │
       ▼
5. Phase별 build-runner 위임 (순차)
   For each Phase:
     ├── Task(subagent_type="build-runner", ...)
     ├── agent 결과 받기 (pass/fail + 요약)
     ├── pass → CHECKLIST 체크 + 다음 Phase
     └── fail → 사용자 에스컬레이션 (AskUserQuestion)
       │
       ▼
6. 모든 Phase 통과
   ├── .status = "complete"
   └── 전체 요약 리포트
```

## Step 1-2: 활성 플랜 탐지

```bash
PROJECT_ROOT=$(pwd)
while [ "$PROJECT_ROOT" != "/" ]; do
  [ -f "$PROJECT_ROOT/.cwm/.initialized" ] && break
  PROJECT_ROOT=$(dirname "$PROJECT_ROOT")
done
[ -f "$PROJECT_ROOT/.cwm/.initialized" ] || exit 1

# 활성 플랜 찾기
ACTIVE_PLAN=""
for status in "$PROJECT_ROOT/.cwm/docs/plans"/*/.status; do
  [ -f "$status" ] || continue
  if grep -qx "active" "$status"; then
    ACTIVE_PLAN=$(dirname "$status")
    break
  fi
done
```

**활성 플랜 없으면:**
```
⚠️ 활성 플랜이 없습니다.
  /cwm:planwithme {작업명}  → 플랜 먼저 수립·승인하세요
```

## Step 3: 테스트 명령 결정

### a. config.yml 우선
```yaml
# .cwm/config.yml
build:
  test_cmd: "npm test"     # 빈값이면 추론
  lint_cmd: "npm run lint" # 빈값이면 추론
  max_retries: 3
```

### b. 추론 규칙

| 매니페스트 | test_cmd | lint_cmd |
|----------|---------|---------|
| `package.json` (scripts.test) | `npm test` | `npm run lint` (있으면) |
| `pyproject.toml` | `pytest` | `ruff check .` |
| `pytest.ini` / `tox.ini` | `pytest` | — |
| `Cargo.toml` | `cargo test` | `cargo clippy -- -D warnings` |
| `go.mod` | `go test ./...` | `go vet ./...` |
| `pubspec.yaml` | `dart test` | `dart analyze` |
| `Makefile` (test 타겟) | `make test` | `make lint` (있으면) |

### c. 추론 실패 시 질문

```
테스트 명령을 찾지 못했습니다. 어떻게 할까요?
- 직접 입력 (예: "yarn test")
- 테스트 없이 진행 (린트만)
- 모두 스킵
```

선택 결과는 **`.cwm/config.yml`에 저장** — 다음 실행부터 재사용.

## Step 5: build-runner 위임

### 호출 형태

```
Task(
  subagent_type="build-runner",
  description="Phase {N}: {이름} 구현",
  prompt="""
[buildwithme 위임]

활성 플랜: {ACTIVE_PLAN}
Phase: {Phase 번호 + 이름}

### 작업 맥락 (읽을 것)
- PLAN.md  — {ACTIVE_PLAN}/PLAN.md
- CONTEXT.md — {ACTIVE_PLAN}/CONTEXT.md
- CHECKLIST.md — {ACTIVE_PLAN}/CHECKLIST.md (이 Phase 항목만)

### 수행할 작업
이 Phase의 체크되지 않은 세부 작업을 모두 구현하라.

### 검증 게이트
1. 린트: `{lint_cmd}` (있을 때만)
2. 테스트: `{test_cmd}` (있을 때만)
실패 시 최대 {max_retries}회 재시도 (에러 분석 → 수정 → 재실행).

### 반환 형식 (마지막에 반드시)
```yaml
status: pass | fail
phase: {Phase 번호}
files_changed:
  - <경로 1>
  - <경로 2>
lint_result: pass | fail | skipped
test_result: pass | fail | skipped
retries_used: 0-{max_retries}
failure_summary: |
  (실패 시에만) 무엇이 왜 실패했는지 3-5줄
next_steps: |
  (실패 시에만) 사용자가 확인해야 할 것
```

### 제약
- 이 Phase의 스코프 밖 파일은 건드리지 말 것
- PLAN.md / CHECKLIST.md / .status 파일 수정 금지 (buildwithme가 처리)
- 테스트 명령을 임의로 바꾸지 말 것
"""
)
```

### agent 결과 처리

```
status == pass:
  - CHECKLIST.md에서 해당 Phase의 체크박스 업데이트 ([ ] → [x])
  - 다음 Phase로 진행

status == fail:
  - AskUserQuestion으로 에스컬레이션 (아래 참조)
```

### 실패 에스컬레이션

```
AskUserQuestion:
"Phase {N}이 실패했습니다.

[failure_summary 출력]

어떻게 할까요?"
- 상세 로그 보기 (agent 출력 전체)
- 다시 시도 (같은 Phase 재위임)
- 이 Phase 스킵 (다음 Phase로)
- 중단 (buildwithme 종료, .status는 active 유지)
```

## Step 6: 완료 처리

```bash
echo "complete" > "$ACTIVE_PLAN/.status"
```

출력:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ {작업명} 구현 + 테스트 완료
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phases: {N}/{N} 통과
린트: {lint_cmd} ✓
테스트: {test_cmd} ✓

변경 파일 (총 {M}개):
  - {파일 1}
  - {파일 2}
  ...

.status → complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 중단/재개

- Phase 중 "중단" 시: CHECKLIST 체크 상태 유지, `.status`는 `active` 그대로
- 다시 `/cwm:buildwithme` 실행하면 미완료 Phase부터 이어서 진행

## Config 기본값 (setupwithme가 생성)

```yaml
build:
  test_cmd: ""
  lint_cmd: ""
  max_retries: 3
  run_on_phase_complete: true
```

## 컨텍스트 절약 효과

- **메인 컨텍스트**: Phase별 YAML 요약(~20줄)만 유지
- **build-runner 컨텍스트**: Read/Edit/Bash 로그는 agent 내부에서 소화 후 소멸
- 큰 플랜(Phase 5+)에서도 메인 컨텍스트가 쌓이지 않음

## 금지 사항

1. 비활성 플랜(`.status != active`) 상태에서 실행 금지
2. agent 반환값 없이 CHECKLIST 임의 체크 금지
3. 테스트 실패 무시하고 다음 Phase로 넘어가기 금지
4. 사용자 승인 없이 `.status`를 `complete`로 바꾸기 금지 (모든 Phase pass 필수)

## 사용 예시

```
# planwithme 승인 후
/cwm:buildwithme

# 중간 중단 후 재개
/cwm:buildwithme   # 미완료 Phase부터
```
