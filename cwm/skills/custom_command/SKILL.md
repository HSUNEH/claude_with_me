---
name: custom_command
description: "CWM HUD(StatusLine) 설치. 플랜 상태, 컨텍스트 바, 호출 카운트 등을 상태줄에 표시한다."
user-invocable: true
---

# CWM HUD 설치

> `/cwm:custom_command` — CWM 전용 HUD를 설치합니다.

## HUD에 표시되는 정보

```
📂 폴더 | 🔀 브랜치 | 컨텍스트 바 | 🔧tool 🤖agent ⚡skill | 📋 활성 플랜 | 5h 리밋
```

## 실행 절차

### 0. 사전 점검

설치 전 먼저 확인:

```bash
node --version
which jq
```

- **Node.js 미설치** → "Node.js가 필요합니다. 설치 후 다시 시도하세요." 출력 후 중단.
- **jq 미설치** → "jq가 필요합니다 (훅 의존성). `apt install jq` 또는 `brew install jq`로 설치하세요." 경고 출력 (중단하지는 않음).

### 1. 현재 statusLine 확인

`~/.claude/settings.json`을 읽어서 `statusLine` 항목을 확인한다.

### 2-A. 이미 설정되어 있는 경우

사용자에게 확인:
```
현재 커스텀 statusLine이 설정되어 있습니다.
CWM HUD로 교체할까요? (y/n)
```

### 2-B. 설정이 없는 경우

바로 설치 진행.

### 3. HUD 설치

`~/.claude/settings.json`에 다음을 추가:

```bash
jq --arg cmd "node ${CLAUDE_PLUGIN_ROOT}/hud/cwm-hud.mjs" \
  '.statusLine = {"type": "command", "command": $cmd}' \
  ~/.claude/settings.json > ~/.claude/settings.json.tmp \
  && mv ~/.claude/settings.json.tmp ~/.claude/settings.json
```

`${CLAUDE_PLUGIN_ROOT}`는 실제 플러그인 설치 경로로 치환한다.
플러그인 경로를 모르면 `~/.claude/plugins/cache/` 에서 cwm 디렉토리를 찾는다.

### 4. 완료

```
✅ CWM HUD 설치 완료

적용하려면 Claude Code를 재시작하세요.
```
