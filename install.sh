#!/bin/bash
# ============================================================
# dev_sys_template 설치 스크립트
# ============================================================
# 사용법:
#   git clone https://github.com/HSUNEH/dev_sys_template
#   bash dev_sys_template/install.sh
#
# 또는 이미 clone된 상태에서:
#   bash install.sh [대상_디렉토리]
# ============================================================

set -euo pipefail

# 스크립트 위치 기준으로 템플릿 디렉토리 결정
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR"

# 대상 디렉토리: 인자로 받거나 템플릿의 상위 디렉토리
TARGET_DIR="${1:-$(dirname "$TEMPLATE_DIR")}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "======================================="
echo " dev_sys_template 설치"
echo "======================================="
echo ""
echo "템플릿: $TEMPLATE_DIR"
echo "대상:   $TARGET_DIR"
echo ""

# 1. 템플릿 검증
if [ ! -d "$TEMPLATE_DIR/.claude" ]; then
  echo "[오류] 템플릿 디렉토리에 .claude/가 없습니다: $TEMPLATE_DIR" >&2
  exit 1
fi

# 2. .claude/ 병합 설치 (기존 사용자 파일 보존)
if [ -d "$TARGET_DIR/.claude" ]; then
  echo "[병합] 기존 .claude/ 감지 — 병합 모드로 설치"

  # 시스템 디렉토리: 템플릿으로 덮어쓰기 (hooks, hooks/lib)
  echo "  [덮어쓰기] hooks/ (시스템 파일)"
  mkdir -p "$TARGET_DIR/.claude/hooks/lib"
  cp -f "$TEMPLATE_DIR/.claude/hooks/"*.sh "$TARGET_DIR/.claude/hooks/" 2>/dev/null || true
  cp -f "$TEMPLATE_DIR/.claude/hooks/"*.yml "$TARGET_DIR/.claude/hooks/" 2>/dev/null || true
  cp -f "$TEMPLATE_DIR/.claude/hooks/lib/"*.sh "$TARGET_DIR/.claude/hooks/lib/" 2>/dev/null || true

  # agents, skills: 템플릿 파일 추가, 기존 사용자 파일 보존
  for DIR in agents skills; do
    if [ -d "$TEMPLATE_DIR/.claude/$DIR" ]; then
      echo "  [병합] $DIR/ (기존 파일 보존)"
      cp -rn "$TEMPLATE_DIR/.claude/$DIR" "$TARGET_DIR/.claude/" 2>/dev/null || \
        rsync -a --ignore-existing "$TEMPLATE_DIR/.claude/$DIR/" "$TARGET_DIR/.claude/$DIR/"
    fi
  done

  # settings.json: 없을 때만 복사
  if [ ! -f "$TARGET_DIR/.claude/settings.json" ]; then
    echo "  [복사] settings.json (신규)"
    cp "$TEMPLATE_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"
  else
    echo "  [유지] settings.json (기존 보존)"
  fi
else
  echo "[복사] .claude/ 복사 중 (신규 설치)..."
  cp -r "$TEMPLATE_DIR/.claude" "$TARGET_DIR/.claude"
fi

# 3. 기존 파일 백업 (_origin)
if [ -d "$TARGET_DIR/docs" ]; then
  if [ ! -d "$TARGET_DIR/docs_origin" ]; then
    echo "[백업] docs/ → docs_origin/ (기존 원본 보존)"
    mv "$TARGET_DIR/docs" "$TARGET_DIR/docs_origin"
  else
    echo "[유지] docs_origin/ 이미 존재 — 기존 원본 보존"
  fi
fi

if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
  if [ ! -f "$TARGET_DIR/CLAUDE_origin.md" ]; then
    echo "[백업] CLAUDE.md → CLAUDE_origin.md (기존 원본 보존)"
    mv "$TARGET_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE_origin.md"
  else
    echo "[유지] CLAUDE_origin.md 이미 존재 — 기존 원본 보존"
  fi
fi

echo "[복사] docs/ 복사 중..."
cp -r "$TEMPLATE_DIR/docs" "$TARGET_DIR/docs"

echo "[복사] CLAUDE.md 복사 중..."
cp "$TEMPLATE_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"

# 4. 실행 권한 설정
echo "[권한] 실행 권한 설정 중..."
chmod +x "$TARGET_DIR/.claude/hooks/"*.sh 2>/dev/null || true
chmod +x "$TARGET_DIR/.claude/hooks/lib/"*.sh 2>/dev/null || true

# 5. 설치 검증
echo ""
echo "--- 설치 검증 ---"
PASS=true

_check() {
  local LABEL="$1"
  local PATH_CHECK="$2"
  if [ -e "$PATH_CHECK" ]; then
    echo "  [OK] $LABEL"
  else
    echo "  [누락] $LABEL"
    PASS=false
  fi
}

_check "settings.json" "$TARGET_DIR/.claude/settings.json"
_check "hooks/*.sh" "$TARGET_DIR/.claude/hooks/plan-guard.sh"
_check "hooks/lib/" "$TARGET_DIR/.claude/hooks/lib/matcher.sh"
_check "skills/" "$TARGET_DIR/.claude/skills/setup/SKILL.md"
_check "agents/" "$TARGET_DIR/.claude/agents/qa-agent.md"
_check "docs/" "$TARGET_DIR/docs/plans"
_check "CLAUDE.md" "$TARGET_DIR/CLAUDE.md"

echo ""

if $PASS; then
  echo "======================================="
  echo " 설치 완료!"
  echo "======================================="
  echo ""
  echo "다음 단계:"
  echo "  1. Claude Code를 시작하세요 (claude)"
  echo "  2. /setup 을 입력하여 초기화 위저드를 실행하세요"
else
  echo "======================================="
  echo " 설치 불완전 - 위 누락 항목을 확인하세요"
  echo "======================================="
  exit 1
fi
