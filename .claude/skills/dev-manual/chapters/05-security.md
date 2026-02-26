# 챕터 5: 보안

## 이 프로젝트의 보안 범위

dev-sys-template은 로컬 CLI 도구(Claude Code)의 Hook/Skill 시스템이므로, 웹 앱 수준의 보안(인증/인가, CSRF 등)은 해당하지 않는다.

대신 아래 항목에 집중한다.

## Shell 스크립트 보안

### 입력 검증

```bash
# DO: jq로 안전하게 JSON 파싱
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# DON'T: eval이나 직접 변수 대입
eval "PROMPT=$INPUT"
```

### 경로 처리

```bash
# DO: 변수를 큰따옴표로 감싸기
if [ -f "$CHECKLIST_FILE" ]; then

# DON'T: 따옴표 없이 사용 (공백 포함 경로에서 깨짐)
if [ -f $CHECKLIST_FILE ]; then
```

### 금지 패턴 (config.yml code_patterns에서 감지)

| 패턴 | 위험 | 대안 |
|------|------|------|
| `eval()` | 코드 인젝션 | 직접 실행 |
| `innerHTML` | XSS | `textContent` 또는 프레임워크 바인딩 |
| `exec()` | 명령 인젝션 | 화이트리스트 기반 실행 |
| 하드코딩 비밀정보 | 유출 | 환경변수 |

## config.yml의 코드 패턴 감지

```yaml
code_patterns:
  security_dangerous_functions:
    pattern: "(eval\\(|innerHTML|exec\\()"
    severity: "critical"
  security_hardcoded_secrets:
    pattern: "(password|secret|api_key)\\s*[:=]\\s*[\"']"
    severity: "critical"
```

이 패턴들은 `post-tool-check.sh`와 `completion-checker.sh`에서 자동 감지된다.
