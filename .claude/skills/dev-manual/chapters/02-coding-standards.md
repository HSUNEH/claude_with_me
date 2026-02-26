# 챕터 2: 코딩 표준

## 파일 네이밍

| 대상 | 규칙 | 예시 |
|------|------|------|
| Shell 스크립트 | kebab-case | `plan-guard.sh`, `config-parser.sh` |
| YAML 설정 | kebab-case | `config.yml` |
| Markdown 문서 | kebab-case 또는 UPPER_CASE | `PLAN.md`, `01-project-overview.md` |
| 디렉토리 | kebab-case | `dev-manual/`, `plan-manager/` |
| 계획 폴더 | kebab-case | `docs/plans/user-auth/` |

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
