---
name: planwithme
description: "개발 계획 수립 및 3문서 자동 생성. 새 작업 시작 전 반드시 실행하여 PLAN.md, CONTEXT.md, CHECKLIST.md + .status 파일을 생성한다."
user-invocable: true
---

# CWM 계획 관리

> 모든 개발 작업은 **계획 수립 → 승인 → 실행** 순서를 따른다.

## ⚠️ 프로젝트 루트 결정 (필수)

플랜 생성/조회 전에 **반드시** 프로젝트 루트를 먼저 결정한다:

1. **현재 작업 디렉토리(CWD)부터 상위로 올라가며** `.cwm/.initialized` 파일을 찾는다
2. `.cwm/.initialized`가 존재하는 디렉토리가 프로젝트 루트이다
3. 모든 플랜 경로는 **이 프로젝트 루트의 절대 경로** 기준으로 생성한다

```bash
# 프로젝트 루트 찾기 예시
PROJECT_ROOT=$(pwd)
while [ "$PROJECT_ROOT" != "/" ]; do
  [ -f "$PROJECT_ROOT/.cwm/.initialized" ] && break
  PROJECT_ROOT=$(dirname "$PROJECT_ROOT")
done
# 못 찾으면 setupwithme 필요
[ -f "$PROJECT_ROOT/.cwm/.initialized" ] || echo "ERROR: .cwm not initialized"
```

**⛔ 절대 금지:**
- 상대 경로(`.cwm/docs/plans/...`)만으로 파일을 생성하지 않는다
- CWM 플러그인 소스 디렉토리 안에 플랜을 생성하지 않는다
- `.cwm/.initialized`를 찾지 못하면 사용자에게 `/cwm:setupwithme` 실행을 안내한다

**⚠️ `cd` 주의:**
- git push 등 Bash 작업 중 `cd`로 하위 디렉토리에 진입한 경우, 플랜 파일 조작 전에 반드시 프로젝트 루트로 돌아오거나, 절대 경로를 사용한다
- CWD가 프로젝트 루트가 아닐 수 있으므로, 항상 `.cwm/.initialized` 기준으로 루트를 재확인한다

## 실행 흐름

```
1. 사용자 작업 지시
       │
       ▼
2. 초기 모호도 채점 (Goal / Scope / Acceptance)
   임계값: ambiguity ≤ 20%
       │
    ┌──┴──┐
    ▼     ▼
> 20%   ≤ 20%
    │     │
    ▼     │
[interviewwithme 위임]
  Skill("cwm:interviewwithme", args=<원 요청>)
  → Socratic Q&A 루프
  → .cwm/docs/briefs/{YYMMDD}{NN}-{주제}.md 생성
  → 명확화된 Goal/Scope/Acceptance 인계
    │     │
    └──┬──┘
       ▼
3. 계획 수립 (interview 결과 있으면 그것을 기반으로)
   ├── 요구사항 분석
   ├── 기존 코드 조사
   └── 구현 전략 설계
       │
       ▼
4. 4파일 생성 → .cwm/docs/plans/{YYMMDD}{NN}-{작업명}/
   ├── PLAN.md         계획서
   ├── CONTEXT.md      맥락 노트 (interview 결과 통합)
   ├── CHECKLIST.md    체크리스트
   └── .status         "pending"
       │
       ▼
5. ⛔ 반드시 멈춤
   ├── 계획 요약 표시
   └── 사용자 승인 대기
       │
       ▼
6. 승인 시:
   ├── .status → "active"
   ├── CHECKLIST 승인 체크
   └── /compact 안내 → 구현 시작
```

## 초기 모호도 채점

요청을 받으면 **내부에서만** 3차원(Goal/Scope/Acceptance) 채점을 수행한다. 사용자에게 숫자는 노출하지 않는다.

| 차원 | 가중치 | 판단 기준 |
|------|-------|----------|
| **Goal** | 0.40 | 목적이 한 문장으로 정의되는가, 결과물이 명확한가 |
| **Scope** | 0.30 | 영향 파일·모듈·외부 의존·비범위가 정의됐는가 |
| **Acceptance** | 0.30 | 완료 기준이 테스트/확인 가능한가 |

**모호도**: `ambiguity = 1 - (goal × 0.40 + scope × 0.30 + acceptance × 0.30)`
**임계값**: `ambiguity > 0.20` → 인터뷰 위임

**예시:**
```
"로그인 기능 만들어줘" → Goal 0.6 / Scope 0.2 / Acceptance 0.1 → 67% → 위임
"src/auth/login.ts의 bcrypt 10→12" → 전부 0.9+ → 3% → 바로 계획 수립
```

## interviewwithme 위임

모호도 > 20%인 경우, 직접 질문하지 말고 **반드시 interviewwithme 스킬에 위임**한다:

```
Skill("cwm:interviewwithme", args="<원 요청 그대로>")
```

interviewwithme가 Socratic Q&A 루프(최대 5라운드)를 수행하고 브리프를 `.cwm/docs/briefs/{YYMMDD}{NN}-{주제}.md`로 저장한 뒤, 다음 구조화 데이터를 인계한다:

- Goal 한 문장
- Scope (포함/제외/제약)
- Acceptance 체크 목록
- 결정 사항 표
- 인터뷰 기록 (Q&A)
- 브리프 파일 경로

### 인계 데이터 → 3문서 매핑

| interviewwithme 산출 | → | planwithme 반영 위치 |
|---------------------|---|---------------------|
| Goal 한 문장 | → | PLAN.md 개요 (목적) |
| Scope (포함/제외/제약) | → | PLAN.md 범위 + CONTEXT.md 제약 |
| Acceptance 체크 목록 | → | CHECKLIST.md 품질 체크 |
| 결정 사항 표 | → | CONTEXT.md 결정 기록 |
| 인터뷰 기록 (Q&A) | → | CONTEXT.md "인터뷰 기록" 섹션 |
| 브리프 파일 경로 | → | CONTEXT.md 참조 자료 링크 |

### 인터뷰 취소 시

사용자가 인터뷰 중 취소하면 interviewwithme가 "cancelled"를 반환한다. 이 경우 3문서 생성을 중단하고 사용자에게:
```
📋 인터뷰가 취소되었습니다. 요청을 다시 명확히 해서 알려주시면 계획을 세우겠습니다.
```

## 3문서 + .status 작성 규칙

### PLAN.md (계획서)

```markdown
# [작업명] 계획서

## 개요
- 목적 (한 줄)
- 범위 (영향 파일/모듈)
- 예상 단계 수

## 현재 상태 분석
- 기존 코드 구조
- 변경 필요 부분

## 구현 계획
### Phase 1: [단계명]
- 구체적 작업 내용
- 예상 변경 파일

### Phase 2: [단계명]
...

## 기술 선택
- 라이브러리/패턴 + 선택 이유

## 리스크
- 예상 문제 + 대응 방안
```

### CONTEXT.md (맥락 노트)

```markdown
# [작업명] 맥락 노트

## 결정 기록
| 결정 사항 | 선택지 | 최종 선택 | 이유 |
|-----------|--------|-----------|------|

## 참조 자료
- 관련 문서/URL
- 참고 코드 위치

## 제약 조건
- 기술적/비즈니스 제약

## 사용자 요구사항 원문
> (사용자 지시 그대로)
```

### CHECKLIST.md (체크리스트)

```markdown
# [작업명] 체크리스트

## 작업 목록
- [ ] Phase 1: [단계명]
  - [ ] 세부 작업 1
  - [ ] 세부 작업 2
- [ ] Phase 2: [단계명]
  - [ ] 세부 작업 1

## 컨텍스트 전환 체크
- [ ] 사용자 승인 완료
- [ ] /compact 안내 출력 완료

## 품질 체크
- [ ] 에러 처리 적용
- [ ] 보안 검토
- [ ] 테스트 작성/통과
```

### .status 파일

플랜 상태를 나타내는 단일 키워드 파일:
- `pending` — 생성됨, 승인 대기
- `active` — 승인됨, 진행 중
- `complete` — 작업 완료

```bash
echo "pending" > {프로젝트 루트}/.cwm/docs/plans/{YYMMDD}{NN}-{작업명}/.status
```

## 문서 저장 위치

```
{프로젝트 루트의 절대 경로}/.cwm/docs/plans/{YYMMDD}{NN}-{작업명}/
├── PLAN.md
├── CONTEXT.md
├── CHECKLIST.md
└── .status
```

- **프로젝트 루트** = `.cwm/.initialized`가 존재하는 디렉토리 (위의 "프로젝트 루트 결정" 참조)
- **폴더명 = `YYMMDD{NN}-작업명`** (예: `26033001-user-auth`, `26033002-api-refactor`)
  - `YYMMDD`: 6자리 날짜 (`date +%y%m%d`)
  - `NN`: 같은 날짜의 생성 순번, 2자리 zero-pad (01, 02, …) — 계산 규칙은 아래 참고
- 작업명은 kebab-case
- 한 작업 = 한 폴더, 4파일이 항상 세트
- **파일 생성 시 반드시 절대 경로 사용** (예: `/Users/me/my-project/.cwm/docs/plans/26033001-user-auth/PLAN.md`)

### 순번 `NN` 계산

폴더 생성 직전에 대상 디렉토리를 스캔해 오늘 날짜의 최대 NN + 1 을 사용한다:

```bash
DATE=$(date +%y%m%d)                    # 예: 260424
TARGET_DIR="$PROJECT_ROOT/.cwm/docs/plans"
LAST=$(ls "$TARGET_DIR" 2>/dev/null \
  | grep -E "^${DATE}[0-9]{2}-" \
  | sed -E "s/^${DATE}([0-9]{2})-.*/\1/" \
  | sort -n | tail -1)
NN=$(printf "%02d" $((10#${LAST:-0} + 1)))
FOLDER="${DATE}${NN}-${KEBAB_NAME}"     # 예: 26042401-user-auth
```

- 오늘 항목이 없으면 `NN=01`
- `10#${LAST:-0}` — `08`, `09` 값이 8진수로 해석되는 것을 방지
- 기존 `YYMMDD-{이름}` (순번 없음) 폴더는 정규식 불일치로 스캔에서 제외 → 공존 가능

## 승인 대기

3문서 생성 후 반드시 요약을 보여주고 멈춘다:

```
📋 계획 수립 완료 — 검토 요청

📂 .cwm/docs/plans/{YYMMDD}{NN}-{작업명}/
  ├── PLAN.md       ← 전체 구현 계획
  ├── CONTEXT.md    ← 결정 근거
  ├── CHECKLIST.md  ← 작업 체크리스트
  └── .status       ← pending

[계획 요약]
  Phase 1: {단계1}
  Phase 2: {단계2}
  ...

⏸️ 검토 후 승인해주세요. 승인 전까지 코드를 작성하지 않습니다.
```

**⛔ 절대 금지: 이 메시지 출력 후 같은 턴에서:**
- 코드 파일을 읽거나 수정하지 않는다
- Bash 명령을 실행하지 않는다
- 사용자의 다음 메시지까지 대기한다

## 승인 처리

사용자가 "확인", "승인", "진행", "좋아", "ㅇㅇ", "ㄱㄱ", "ok", "go" 등 동의하면:

### Step 1: 상태 변경
```bash
echo "active" > {프로젝트 루트}/.cwm/docs/plans/{YYMMDD}{NN}-{작업명}/.status
```

CHECKLIST.md의 "사용자 승인 완료" 체크:
```markdown
- [x] 사용자 승인 완료
```

### Step 2: /compact 안내 후 멈춤

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 계획이 승인되었습니다
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📂 .cwm/docs/plans/{YYMMDD}{NN}-{작업명}/.status → active


컨텍스트를 정리하면 더 원활합니다.

👉 /compact 후 "계속" 이라고 입력하세요.
   (바로 진행하려면 "계속 진행" 이라고 입력하세요)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

CHECKLIST.md 체크:
```markdown
- [x] /compact 안내 출력 완료
```

**⛔ 이 메시지 출력 후 이 턴에서 어떤 도구도 호출하지 않는다.**

### Step 3: 구현 시작 (다음 턴 또는 /compact 후)

사용자가 돌아오면 (**반드시 이 순서를 따른다**):
1. **프로젝트 루트를 다시 결정한다** — `.cwm/.initialized` 파일을 찾아 절대 경로 확인
2. `{프로젝트 루트}/.cwm/docs/plans/` 아래에서 `.status`가 `active`인 플랜 폴더를 찾는다
3. 해당 폴더의 PLAN.md와 CHECKLIST.md를 **파일에서 다시 읽는다** (대화 히스토리 의존 X)
4. `/cwm:dev-manual`로 관련 챕터 참조
5. Phase 1부터 순서대로 구현 (이미 체크된 항목은 건너뜀)
6. 각 세부 작업 완료 시 CHECKLIST.md 업데이트

## 작업 완료

모든 Phase 완료 시:
```bash
echo "complete" > {프로젝트 루트}/.cwm/docs/plans/{YYMMDD}{NN}-{작업명}/.status
```

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ {작업명} 완료
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

.cwm/docs/plans/{YYMMDD}{NN}-{작업명}/.status → complete
```

## 중요 규칙

1. **계획 먼저** — 코드 한 줄 전에 3문서부터
2. **승인 필수** — 같은 턴에서 코드 작성 금지
3. **.status로 추적** — pending/active/complete
4. **실시간 갱신** — CHECKLIST.md 계속 업데이트
5. **맥락 보존** — 새 세션에서도 .cwm/docs/plans/ 읽으면 이어서 가능
