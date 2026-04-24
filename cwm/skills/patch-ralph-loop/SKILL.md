---
name: patch-ralph-loop
description: "ralph-loop 플러그인 stop-hook 의 세션 격리 버그(같은 프로젝트의 무관한 세션이 block 되는 문제)를 로컬에서 임시 패치한다. 업스트림 수정 전까지의 방어 조치."
user-invocable: true
---

# ralph-loop 세션 격리 패치

> `/cwm:patch-ralph-loop` — `claude-plugins-official` 마켓플레이스의 `ralph-loop` 플러그인 훅에
> 세션 격리 방어 로직을 삽입한다.

## 문제

`ralph-loop` 이 한 번 실행되면 `.claude/ralph-loop.local.md` 상태 파일이 남는다.
여기에 `session_id:` 필드가 비어있으면, 그 파일이 있는 프로젝트 CWD 에서 여는
**모든 Claude Code 세션**이 매 턴 stop-hook 의 block 결정을 받아 무관한 활성
플랜을 실행하려 한다.

## 실행 절차

### 1. CWM 플러그인 루트 탐색

플러그인은 보통 `~/.claude/plugins/marketplaces/cwm/cwm/` 에 설치된다.
`$CLAUDE_PLUGIN_ROOT` 환경 변수가 있으면 그 값을 우선 사용:

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/plugins/marketplaces/cwm/cwm}"
PATCH_DIR="$PLUGIN_ROOT/patches/ralph-loop"
```

### 2. 현재 상태 확인

```bash
bash "$PATCH_DIR/check-stop-hook.sh"
```

exit 코드:
- `0` = 이미 PATCHED — 사용자에게 "이미 적용되어 있습니다" 안내 후 종료
- `1` = NOT PATCHED — 3단계로 진행
- `2` = ralph-loop 미설치 — 사용자에게 "ralph-loop 이 설치되어 있지 않아 패치 불필요" 안내 후 종료

### 3. 패치 적용

```bash
bash "$PATCH_DIR/patch-stop-hook.sh"
```

exit 코드:
- `0` = 적용 성공 (또는 idempotent 경로)
- `2` = SHA256 드리프트 감지 (플러그인 업데이트됨) — 사용자에게:
  1. ralph-loop 이 이미 업스트림에서 수정되었을 가능성이 있음을 안내
  2. `check-stop-hook.sh` 로 현재 훅의 동작을 직접 재검증 권장
  3. 강제로 진행하려면 `--force` 옵션 (주의 필요)
- 그 외 = 에러 — stderr 메시지 그대로 사용자에게 전달

### 4. 검증

```bash
bash "$PATCH_DIR/check-stop-hook.sh"     # PATCHED 확인
bash "$PATCH_DIR/test-patch.sh"          # 3가지 세션 격리 케이스 스모크 테스트
```

### 5. 요약 보고

사용자에게 한국어로 간결히:
- 적용 대상 파일 경로
- 원본 SHA / 백업 위치
- 롤백 방법 1줄

## 사후 주의사항

- `omc update` 또는 `/plugin` 으로 ralph-loop 이 재설치되면 원본이 덮어써진다 — 사용자에게
  "재설치 후에는 `/cwm:patch-ralph-loop` 을 한 번 더 실행해 주세요" 안내 포함.
- 이 패치는 **업스트림 머지 전까지의 임시책**임을 명시. 업스트림 수정 PR이 들어오면
  CWM 다음 버전에서 `patches/ralph-loop/` 가 제거될 예정.

## 롤백 안내

문제가 생겼을 때 사용자에게 제공할 한 줄:

```bash
cp "$PATCH_DIR/snapshots/stop-hook.<sha-short>.orig" <원본 경로>
```

또는 `/plugin uninstall ralph-loop && /plugin install ralph-loop` 으로 깨끗하게 재설치.

## 실패 모드별 대응

| 실패 | 대응 |
|------|------|
| `patch-stop-hook.sh` 권한 없음 | `chmod +x` 안내 후 재시도 |
| SHA 드리프트 | 업스트림이 이미 수정했을 가능성 높음 — `check-stop-hook.sh` 로 동작 직접 확인, 빈 `session_id` 로 케이스 재현 시도 |
| `bash -n` 문법 검사 실패 | 스크립트가 원본 복원하므로 상태 안전 — 사용자에게 이슈 제보 요청 |
| `ralph-loop` 미설치 | 패치 불필요, 종료 |

## 관련 파일

- `$PATCH_DIR/patch-stop-hook.sh` — idempotent 적용기
- `$PATCH_DIR/check-stop-hook.sh` — 상태 점검
- `$PATCH_DIR/test-patch.sh` — 스모크 테스트
- `$PATCH_DIR/README.md` — 상세 문서
- `$PATCH_DIR/snapshots/*.orig` — 원본 백업
