---
name: push
description: "Git 커밋 및 푸쉬. 작업 완료 후 반드시 프로젝트 루트로 복귀한다."
user-invocable: true
---

# CWM Git Push

> `/cwm:push` — 변경사항을 커밋하고 푸쉬한다. 디렉토리 이동 없이 `git -C`를 사용한다.

## 실행 절차

### 0. 프로젝트 루트 결정

`.cwm/.initialized`를 찾아 프로젝트 루트를 결정한다:

```bash
PROJECT_ROOT=$(pwd)
while [ "$PROJECT_ROOT" != "/" ]; do
  [ -f "$PROJECT_ROOT/.cwm/.initialized" ] && break
  PROJECT_ROOT=$(dirname "$PROJECT_ROOT")
done
```

프로젝트 루트가 git 저장소가 아닌 경우, 하위 폴더에서 `.git`을 찾아 `GIT_ROOT`로 사용한다.

### 1. 상태 확인

**`cd` 대신 `git -C <경로>` 옵션을 사용하여 디렉토리 이동 없이 작업한다.**

```bash
git -C "$GIT_ROOT" status
git -C "$GIT_ROOT" diff
```

### 2. 커밋

변경사항이 있으면:

```bash
git -C "$GIT_ROOT" add -A
git -C "$GIT_ROOT" commit -m "커밋 메시지

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

- 커밋 메시지는 **한국어**로, 간결하게 (50자 이내)
- `$ARGUMENTS`가 있으면 커밋 메시지로 사용

### 3. 푸쉬

```bash
git -C "$GIT_ROOT" push origin main
```

- 현재 브랜치가 main이 아니면 해당 브랜치로 푸쉬
- remote가 없으면 사용자에게 안내

### 4. 결과 요약

```
✅ Push 완료
  - 커밋: {커밋 메시지 요약}
  - 브랜치: {브랜치명}
  - 변경 파일: {N}개
```

## 디렉토리 복귀 규칙

**⛔ 절대 금지:**
- `cd`로 다른 디렉토리에 이동한 채로 작업을 종료하지 않는다

**필수 규칙:**
- 가능하면 `git -C <경로>` 옵션을 사용하여 디렉토리 이동 없이 작업
- 부득이하게 `cd`로 이동한 경우, 모든 작업 완료 후 반드시 프로젝트 루트로 복귀:
  ```bash
  cd "$PROJECT_ROOT"
  ```
- push 완료 후 `pwd`로 현재 위치가 프로젝트 루트인지 확인
