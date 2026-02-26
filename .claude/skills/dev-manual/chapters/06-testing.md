# 챕터 6: 테스트

## 테스트 전략

이 프로젝트는 Bash/YAML/Markdown 기반이므로 자동화된 단위 테스트 프레임워크 대신 **수동 검증 + Hook 자동 감지**로 품질을 관리한다.

## Shell 스크립트 검증

### shellcheck

```bash
# 문법/품질 검사
shellcheck hooks/*.sh hooks/lib/*.sh
```

### 수동 테스트 방법

```bash
# Hook에 직접 JSON 입력 전달
echo '{"prompt":"새 기능 만들어줘","cwd":"/path/to/project"}' | bash hooks/plan-guard.sh

# 종료 코드 확인
echo $?  # 0=통과, 2=차단
```

### config.yml 파싱 테스트

```bash
# config-parser가 올바르게 값을 읽는지 확인
source hooks/lib/matcher.sh
match_keywords "수정해줘"   # → "dev" 출력 기대
detect_intent "새 API 만들어" # → "new_feature" 출력 기대
```

## 자동 품질 검사 (Hook 기반)

| Hook | 타이밍 | 검사 내용 |
|------|--------|-----------|
| post-tool-check | 매 수정 후 | 코드 패턴 감지 (eval, 하드코딩 등) |
| completion-checker | 응답 완료 후 | 린트 + 코드 패턴 이중 검사 |

### completion-checker 분기

| 오류 수 | 동작 |
|---------|------|
| 0건 | 통과 |
| 1~3건 | 즉시 수정 안내 |
| 4건+ | 서브에이전트 자동 위임 |

## 서브에이전트 테스트

test-agent가 자동 투입되면:
1. 기능 테스트 수행
2. 오류 진단
3. `docs/reports/test-report-{날짜}.md` 보고서 작성

## 검증 체크리스트

- [ ] Hook에 JSON 입력을 넣었을 때 기대한 종료 코드가 나오는가?
- [ ] config.yml 변경 후 매칭 결과가 올바른가?
- [ ] sync 스크립트 실행 후 설치 사본이 정상 갱신되는가?
