# ralph-loop stop-hook 로컬 패치

**대상**: `claude-plugins-official` 마켓플레이스의 `ralph-loop` 플러그인
**증상**: 같은 프로젝트 CWD의 **무관한 Claude Code 세션**들이 매 턴 block 결정을 받아, 전혀 관계없는 활성 플랜을 실행하려 함
**원인**: stop-hook 의 세션 격리 가드가 `session_id:` 값이 비어있을 때 우회됨 (`[[ -n "$STATE_SESSION" ]]` 이 빈 문자열을 false 로 판정)
**성질**: 업스트림 수정 전까지의 **임시 패치**

## 사용 (추천: 스킬 호출)

CWM 이 설치되어 있다면:

```
/cwm:patch-ralph-loop
```

## 사용 (수동)

```bash
# 적용
bash ~/.claude/plugins/marketplaces/cwm/cwm/patches/ralph-loop/patch-stop-hook.sh

# 상태 확인
bash ~/.claude/plugins/marketplaces/cwm/cwm/patches/ralph-loop/check-stop-hook.sh

# 기능 테스트
bash ~/.claude/plugins/marketplaces/cwm/cwm/patches/ralph-loop/test-patch.sh
```

- idempotent: 이미 적용되어 있으면 "already applied" 출력 후 종료
- SHA256 드리프트 감지 시 중단 (강제 진행은 `--force`, 권장하지 않음)
- 원본은 `snapshots/stop-hook.<sha-short>.orig` 로 자동 백업

## 재적용 시점

다음 경우 다시 실행 필요:
- `omc update` 또는 `/plugin` 명령으로 ralph-loop 재설치 후
- Claude Code 재시작 후 `/ralph-loop:ralph-loop` 실행 시 무관한 세션이 영향을 받는다면 `check-stop-hook.sh` 로 상태 먼저 확인

## 롤백

```bash
cp <snapshots/stop-hook.*.orig> \
   ~/.claude/plugins/marketplaces/<...>/plugins/ralph-loop/hooks/stop-hook.sh
```

또는 `/plugin uninstall ralph-loop && install ralph-loop`.

## 패치 내용

원본:

```bash
if [[ -n "$STATE_SESSION" ]] && [[ "$STATE_SESSION" != "$HOOK_SESSION" ]]; then
  exit 0
fi
```

패치 후:

```bash
# [CWM-LOCAL-PATCH session-isolation v1] — remove when upstream lands
if [[ -n "$STATE_SESSION" ]]; then
  if [[ "$STATE_SESSION" != "$HOOK_SESSION" ]]; then
    exit 0
  fi
else
  if echo "$FRONTMATTER" | grep -q "^session_id:"; then
    echo "⚠️  Ralph loop: session_id field is empty — refusing to block other sessions (CWM local patch)" >&2
    exit 0
  fi
  # session_id 키 자체가 없는 레거시 파일만 fall-through
fi
# [/CWM-LOCAL-PATCH]
```

불변식:
- `session_id` 값 있음 + 현재 세션과 다름 → exit 0 (기존)
- `session_id` 키 있음 + 값 비어있음 → exit 0 + stderr 경고 (**신규**)
- `session_id` 키 없음 (레거시) → fall-through (기존)

## 해제 조건

업스트림(`claude-plugins-official`)에서 동등한 수정 머지 시:

1. `check-stop-hook.sh` 로 현재 상태 확인
2. 플러그인 reinstall 로 최신 원본 적용 (패치 자동 제거됨)
3. `test-patch.sh` 로 case-B 가 여전히 안전한지 재확인
4. 다음 CWM 업데이트에서 `cwm/patches/ralph-loop/` 제거 예정
