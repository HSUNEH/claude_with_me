# 챕터 2: 코딩 표준

## 파일 네이밍

| 대상 | 규칙 | 예시 |
|------|------|------|
| Shell 스크립트 | kebab-case | `plan-guard.sh`, `config-parser.sh` |
| YAML 설정 | kebab-case | `config.yml` |
| Markdown 문서 | kebab-case 또는 UPPER_CASE | `PLAN.md`, `01-project-overview.md` |
| 디렉토리 | kebab-case | `dev-manual/`, `plan-manager/` |
| 계획 폴더 | kebab-case | `docs/plans/user-auth/` |

## 코드 작성 원칙

코드를 작성하거나 수정할 때 아래 4원칙을 항상 따른다.

### 1. 먼저 생각하라 (Think Before Coding)

```
DO:
- 구현 전에 "이 변경의 전제 조건은 무엇인가?"를 명시한다
- 2가지 이상 접근법을 떠올린 뒤 가장 단순한 것을 선택한다
- 불확실하면 코드를 쓰기 전에 질문한다

DON'T:
- 바로 코드부터 쓰고 "되겠지" 하고 넘어간다
- 한 가지 방법만 생각하고 구현한다
```

### 2. 단순하게 하라 (Simplicity First)

```
DO:
- 동작하는 가장 짧은 구현을 선택한다
- 3줄 반복이 추상화보다 낫다 (사용처가 1~2개일 때)
- 현재 요구사항만 충족시킨다

DON'T:
- "나중에 필요할 것 같아서" 확장 포인트를 만든다
- 한 번만 쓰는 로직을 함수로 추출한다
- 에러 핸들링을 발생 불가능한 경우까지 추가한다
```

### 3. 요청한 것만 바꿔라 (Surgical Changes)

```
DO:
- 변경 파일 수를 최소화한다
- diff가 작을수록 좋은 변경이다
- 변경한 줄만 리뷰 범위로 본다

DON'T:
- "보이는 김에" 주변 코드를 정리한다
- 수정과 무관한 주석, docstring, 타입 힌트를 추가한다
- 리팩터링을 기능 변경에 끼워넣는다
```

### 4. 완료 기준을 먼저 정하라 (Goal-Driven Execution)

```
DO:
- 구현 전에 "무엇이 되면 끝인가?"를 한 문장으로 정의한다
- CHECKLIST.md의 체크 항목이 곧 완료 기준이다
- 기준을 충족하면 즉시 멈춘다

DON'T:
- 완료 기준 없이 "좋아질 때까지" 수정한다
- 기준을 충족한 뒤 추가 개선을 시도한다
```

## Shell 스크립트 규칙

### 변수 네이밍
```bash
# DO: UPPER_SNAKE_CASE
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# DON'T: camelCase나 소문자
scriptDir="..."
prompt="..."
```

### 입력 처리
```bash
# DO: Hook 입력은 stdin JSON → jq로 파싱
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# DON'T: 인자로 받기
PROMPT=$1
```

### 종료 코드
```bash
exit 0   # 통과 (Hook 메시지는 stdout으로 전달)
exit 2   # 차단 (에러 메시지는 stderr로 출력)
```

### 에러 출력
```bash
# DO: 차단 메시지는 stderr
cat >&2 <<'MSG'
⛔ 에러 메시지
MSG
exit 2

# DO: 안내 메시지는 stdout
cat <<'MSG'
📋 안내 메시지
MSG
exit 0
```

### 공통 유틸리티 로드
```bash
# DO: 상대 경로로 lib 로드
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/matcher.sh"
```

## YAML (config.yml) 규칙

- 최상위 키는 기능 단위로 그룹화: `keywords`, `intents`, `locations`, `code_patterns`, `completion_check`, `agents`, `general`
- 정규식 패턴은 큰따옴표로 감싸기
- 주석으로 각 섹션 구분

## Markdown 규칙

- 계획 3문서: PLAN.md, CONTEXT.md, CHECKLIST.md (대문자)
- 체크리스트 상태 아이콘: 🔴 시작 전 / 🟡 진행 중 / 🟢 완료
- 테이블 사용 시 헤더 구분선 필수
