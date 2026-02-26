# 챕터 4: 에러 처리

## Shell 스크립트 에러 처리

### 종료 코드 규칙

| 코드 | 의미 | 용도 |
|------|------|------|
| `exit 0` | 성공/통과 | Hook이 안내 메시지를 출력하고 정상 진행 |
| `exit 2` | 차단 | Hook이 작업을 차단하고 에러 메시지 표시 |

### 안전한 스크립트 시작

```bash
# sync 스크립트 등 유틸리티
set -euo pipefail

# Hook 스크립트는 set -e 사용하지 않음 (grep 실패 등이 정상 흐름)
```

### 에러 출력 분리

```bash
# 차단 메시지 → stderr (Claude Code가 에러로 인식)
cat >&2 <<'MSG'
⛔ [에러] 내용
MSG
exit 2

# 안내 메시지 → stdout (Claude Code가 정보로 인식)
cat <<'MSG'
📋 [안내] 내용
MSG
exit 0
```

### 방어적 파일 접근

```bash
# DO: 파일 존재 확인 후 접근
[ -f "$checklist" ] || continue
if grep -q "🟡 진행 중" "$checklist" 2>/dev/null; then

# DO: 디렉토리 존재 확인
if [ ! -d "$PLANS_DIR" ]; then

# DON'T: 존재 확인 없이 바로 접근
grep "패턴" "$file"
```

### config.yml 폴백 패턴

```bash
# config에서 읽기 시도 → 실패하면 내장 기본값
if $_HAS_CONFIG 2>/dev/null; then
  VALUE=$(cfg_get "section" "key" 2>/dev/null)
fi
if [ -z "$VALUE" ]; then
  VALUE="기본값"
fi
```

## 에러 메시지 형식

```
───────────────────────────────────────────
⛔/⚠️/📋 [카테고리] 제목
───────────────────────────────────────────

상세 설명

💡 해결 방법 안내
───────────────────────────────────────────
```

- ⛔: 차단 (exit 2)
- ⚠️: 경고 (exit 0, 안내만)
- 📋: 정보 (exit 0, 컨텍스트 안내)
