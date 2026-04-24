---
name: interviewwithme
description: "범용 요구사항 명확화 스킬. 모호한 요청을 Socratic Q&A로 3차원(Goal/Scope/Acceptance) 채점하며 명확성 임계값(20%)에 도달할 때까지 한 번에 한 질문씩. 단독 호출 가능하며 planwithme에서 자동 위임되기도 함."
user-invocable: true
argument-hint: <명확화할 주제 또는 요청>
---

# CWM 요구사항 명확화 인터뷰

> 모호한 요청을 바로 실행하지 말고, **채점 → 질문 → 재채점** 루프로 명확성을 끌어올린 뒤 산출물로 내보낸다.

## 언제 쓰는가

- 사용자 요청이 모호할 때 (**Claude가 initial ambiguity > 20% 판단** 시)
- 계획·기획·구현 착수 전 요구사항 정리
- planwithme에서 자동 위임받았을 때
- 단독: `/cwm:interviewwithme <주제>` — 요구사항 브리프 문서만 뽑기

## 적용 범위

코드 작업 **및** 그 외(문서 기획, 아이디어 정리 등) 모두. 3차원 채점은 주제에 맞게 유연하게 해석:

| 차원 | 가중치 | 코드 작업 해석 | 범용 해석 |
|------|-------|---------------|----------|
| **Goal** | 0.40 | 무엇을 만드는가, 결과물이 명확한가 | 목적·결과가 한 문장으로 정의되는가 |
| **Scope** | 0.30 | 영향 파일·모듈·제약·비범위 | 경계·포함/제외·제약 |
| **Acceptance** | 0.30 | 완료 기준, 테스트 가능한가 | "됐다"를 어떻게 판단하나 |

**모호도:** `ambiguity = 1 - (goal × 0.40 + scope × 0.30 + acceptance × 0.30)`

**임계값: 20%** (ambiguity ≤ 0.20)

## 실행 흐름

```
1. 주제 수신 + 프로젝트 루트 결정 (.cwm/.initialized)
       │
       ▼
2. 초기 채점 (Claude 내부, 숫자 비공개)
   Goal / Scope / Acceptance × 0.0-1.0
       │
    ┌──┴──┐
    ▼     ▼
≤ 20%   > 20%
    │     │
    │     ▼
    │  3. 인터뷰 루프 (최대 5라운드)
    │     ├── 가장 낮은 차원 1개 겨냥 질문 (AskUserQuestion)
    │     ├── 답변 → 재채점
    │     └── ≤ 20% or 5라운드 도달 → 종료 선택지
    │     │
    └─────┤
          ▼
4. 산출물 생성 → .cwm/docs/briefs/{YYMMDD}{NN}-{주제}.md
   ├── Goal / Scope / Acceptance 정리
   ├── 인터뷰 기록 표
   └── 최종 모호도 + 차원별 점수
       │
       ▼
5. 호출자로 복귀
   ├── 단독 호출 → 브리프 경로 안내
   └── planwithme 위임 → 데이터 반환 (CONTEXT.md에 통합됨)
```

## Step 1: 초기 채점

사용자에게 숫자를 보여주지 않고 **내부 판단**. 각 차원 0.0-1.0:

- **0.9+** : 명확 — 즉시 답할 수 있음
- **0.6-0.9** : 대부분 명확 — 부차적 질문만
- **0.3-0.6** : 가정 있음 — 핵심 질문 남음
- **0.0-0.3** : 거의 모름 — 방향부터 불명

**모호도 ≤ 20%이면 인터뷰 스킵**, 바로 Step 4로.

**예시:**
```
요청: "로그인 기능 만들어줘"
Goal 0.6 / Scope 0.2 / Acceptance 0.1 → 67% → 인터뷰 진입

요청: "src/auth/login.ts의 bcrypt 라운드를 10 → 12로"
Goal 1.0 / Scope 1.0 / Acceptance 0.9 → 3% → 스킵
```

## Step 2: 모드 진입 안내

```
📋 요구사항을 조금 더 명확히 하겠습니다. 몇 가지 여쭤볼게요.
```

## Step 3: 인터뷰 루프

### 질문 생성 규칙

- **1라운드 = 1질문** (절대 배치 금지)
- 가장 낮은 점수 차원을 겨냥
- `AskUserQuestion` 사용 — 2-4개 선택지 + Other 자동
- 가정 노출용 ("이게 당연하다고 가정했는데, 맞나요?")
- **코드에서 확인 가능한 내용은 먼저 Read/Grep** — 사용자에게 묻지 않음

**차원별 질문 스타일:**

| 차원 | 질문 유형 |
|------|----------|
| Goal | "X라고 했는데, 구체적으로 어떤 결과를 원하세요?" |
| Scope | "이건 기존 Y를 확장하나요, 아니면 별도로?" / "이 기능은 Z를 포함하나요?" |
| Acceptance | "완료됐다는 걸 어떻게 확인하실 건가요?" / "이런 동작이면 OK인가요?" |

### 라운드 헤더

```
Round {n} | Targeting: {최약 차원} | 현재 명확성: {대략적 표시, 숫자 X}
```

### 재채점

답변 받으면 내부 재채점, 결과 비공개. 차원 하나라도 0.05+ 움직이면 다음 최약 차원으로 이동.

### 종료 판정

- `ambiguity ≤ 0.20` → Step 3b (사용자 선택)
- **5라운드 하드 캡**: 도달 시 "현재 수준으로 진행할까요?" 질문

### Step 3b: 종료 선택지

임계값 도달 시 `AskUserQuestion`:

```
"요구사항이 충분히 명확해졌습니다. 어떻게 할까요?"
- 이제 브리프 생성 (권장)
- 한 가지 더 묻기
- 취소
```

**취소/롤백:** 사용자가 "취소"·"그만" 응답 시:
- 현재까지 내용을 `.cwm/docs/briefs/{YYMMDD}{NN}-{주제}-incomplete.md`로 저장
- 호출자에게 "cancelled" 반환

## Step 4: 브리프 생성

```bash
# 프로젝트 루트 찾기
PROJECT_ROOT=$(pwd)
while [ "$PROJECT_ROOT" != "/" ]; do
  [ -f "$PROJECT_ROOT/.cwm/.initialized" ] && break
  PROJECT_ROOT=$(dirname "$PROJECT_ROOT")
done
[ -f "$PROJECT_ROOT/.cwm/.initialized" ] || PROJECT_ROOT=$(pwd)

DATE=$(date +%y%m%d)
# 주제는 kebab-case
BRIEFS_DIR="$PROJECT_ROOT/.cwm/docs/briefs"
mkdir -p "$BRIEFS_DIR"

# 순번 NN 계산 (같은 날짜의 기존 항목 최댓값 + 1, 없으면 01)
LAST=$(ls "$BRIEFS_DIR" 2>/dev/null \
  | grep -E "^${DATE}[0-9]{2}-" \
  | sed -E "s/^${DATE}([0-9]{2})-.*/\1/" \
  | sort -n | tail -1)
NN=$(printf "%02d" $((10#${LAST:-0} + 1)))

# 브리프를 "$BRIEFS_DIR/${DATE}${NN}-${TOPIC}.md" 로 Write
# 취소된 경우는 "$BRIEFS_DIR/${DATE}${NN}-${TOPIC}-incomplete.md" (동일 NN 재사용)
```

### 브리프 형식

```markdown
# 요구사항 브리프: {주제}

_작성일: YYYY-MM-DD | 라운드: N | 최종 모호도: X%_

## 원 질의
> {사용자 원문}

## 명확화된 요구사항

### Goal (0.XX)
{한 문장으로 정리한 목적}

### Scope (0.XX)
- 포함: {...}
- 제외: {...}
- 제약: {...}

### Acceptance (0.XX)
- [ ] {확인 가능한 기준 1}
- [ ] {확인 가능한 기준 2}
...

## 인터뷰 기록

| R | 질문 | 답변 | 움직인 차원 |
|---|------|------|-------------|
| 1 | ... | ... | Goal 0.6 → 0.9 |
| 2 | ... | ... | Scope 0.2 → 0.8 |
| ... | | | |

## 결정 사항
| 결정 | 선택지 | 최종 | 근거 |
|------|--------|------|------|
| ... | ... | ... | ... |

## 드러난 가정
- {이전에 암묵적이었는데 인터뷰로 표면화된 가정}
```

## Step 5: 호출자 복귀

### 단독 호출 시

```
📄 브리프 저장: .cwm/docs/briefs/{YYMMDD}{NN}-{주제}.md

최종 명확성: Goal {g} / Scope {s} / Acceptance {a}
모호도: {X}%
```

### planwithme 위임 시

브리프를 생성하되, planwithme에 다음 구조화 데이터를 **인계**:
- Goal 한 문장 → PLAN.md 개요
- Scope (포함/제외/제약) → PLAN.md 범위 + CONTEXT.md 제약
- Acceptance 목록 → CHECKLIST.md 품질 체크
- 결정 사항 표 → CONTEXT.md 결정 기록
- 인터뷰 기록 → CONTEXT.md "인터뷰 기록 (interviewwithme)" 섹션
- 브리프 파일 링크 → CONTEXT.md 참조 자료

planwithme는 이 데이터로 3문서를 채운다.

## 금지 사항

1. 라운드당 2개 이상 질문
2. 채점 숫자를 사용자에게 노출 (혼란 유발)
3. 코드에서 읽을 수 있는 정보를 사용자에게 질문
4. 임계값 미달인데 브리프로 강제 종료 — 5라운드 도달 전까지는 계속
5. 5라운드 초과 — 넘으면 "현재 수준으로 진행?" 질문 필수

## 사용 예시

```
/cwm:interviewwithme 로그인 기능 만들고 싶은데
/cwm:interviewwithme 팀 문서 템플릿 정리
```

planwithme 내부 위임 시에는 Skill 도구로 호출:
```
Skill("cwm:interviewwithme", args="<원 요청>")
```
