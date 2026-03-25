---
name: setup
description: "CWM 환경 설정. HUD 설치, 전역 설정 등 플러그인 환경을 구성한다. 프로젝트 세팅은 /cwm:setupwithme 을 사용하세요."
user-invocable: true
---

# CWM 환경 설정

> `/cwm:setup` — CWM 플러그인 환경을 구성합니다.
> 프로젝트별 세팅은 `/cwm:setupwithme` 을 사용하세요.

## 실행 시 수행하는 작업

### 1. HUD (StatusLine) 설치

CWM 전용 HUD를 설치합니다. 다음 정보를 표시합니다:
- 📂 폴더 | 🔀 git 브랜치 | 컨텍스트 사용량 바
- 🔧 tool / 🤖 agent / ⚡ skill 호출 카운트
- 📋 활성 플랜 이름 (CWM 전용)
- 5시간 Rate Limit 바

**설치 방법:**

`~/.claude/settings.json`의 `statusLine` 항목을 확인합니다.

#### 이미 statusLine이 설정되어 있는 경우

사용자에게 물어봅니다:
```
현재 커스텀 statusLine이 설정되어 있습니다.
CWM HUD로 교체할까요?

1. CWM HUD로 교체
2. 유지 (변경 없음)
```

#### statusLine이 없는 경우

자동으로 설정합니다:

```bash
# settings.json에 statusLine 추가
jq --arg cmd "node ${CLAUDE_PLUGIN_ROOT}/hud/cwm-hud.mjs" \
  '.statusLine = {"type": "command", "command": $cmd}' \
  ~/.claude/settings.json > ~/.claude/settings.json.tmp \
  && mv ~/.claude/settings.json.tmp ~/.claude/settings.json
```

설정 후 메시지:
```
✅ CWM HUD 설치 완료

HUD에 표시되는 정보:
  📂 폴더 | 🔀 브랜치 | 컨텍스트 바 | 호출 카운트 | 📋 플랜 | 5h 리밋

적용하려면 Claude Code를 재시작하세요.
```

### 2. 환경 확인

다음 항목을 점검하고 결과를 표시합니다:

```
CWM 환경 점검:

  ✅ jq 설치됨
  ✅ Node.js 설치됨
  ✅ HUD 설정 완료
  ⚠️ 프로젝트 세팅 미완료 (/cwm:setupwithme 실행 필요)
```

- `jq` — 훅 스크립트 의존성
- `node` — HUD 실행에 필요
- HUD — statusLine 설정 여부
- 프로젝트 — `.cwm/.initialized` 마커 존재 여부

### 3. 완료 메시지

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ CWM 환경 설정 완료
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

다음 단계:
  /cwm:setupwithme  → 프로젝트별 세팅 (처음 사용 시)
  /cwm:planwithme   → 작업 플랜 생성
  /cwm:dev-manual   → 개발 매뉴얼 참조

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 참고

| 명령어 | 범위 | 용도 |
|--------|------|------|
| `/cwm:setup` | 전역 (1회) | HUD, 환경 확인 |
| `/cwm:setupwithme` | 프로젝트 (프로젝트마다) | config.yml, CLAUDE.md, docs/ |
