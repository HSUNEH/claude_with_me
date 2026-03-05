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

# 2. 기존 .claude/ 백업
if [ -d "$TARGET_DIR/.claude" ]; then
  BACKUP_DIR="$TARGET_DIR/.claude.backup.$(date +%Y%m%d%H%M%S)"
  echo "[백업] 기존 .claude/ -> $(basename "$BACKUP_DIR")"
  mv "$TARGET_DIR/.claude" "$BACKUP_DIR"
fi

# 3. 파일 복사
echo "[복사] .claude/ 복사 중..."
cp -r "$TEMPLATE_DIR/.claude" "$TARGET_DIR/.claude"

echo "[복사] docs/ 복사 중..."
if [ -d "$TARGET_DIR/docs" ]; then
  # docs/plans, docs/logs, docs/reports는 보존
  for SUBDIR in plans logs reports; do
    if [ -d "$TEMPLATE_DIR/docs/$SUBDIR" ] && [ ! -d "$TARGET_DIR/docs/$SUBDIR" ]; then
      cp -r "$TEMPLATE_DIR/docs/$SUBDIR" "$TARGET_DIR/docs/$SUBDIR"
    fi
  done
else
  cp -r "$TEMPLATE_DIR/docs" "$TARGET_DIR/docs"
fi

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
  echo "  1. Claude Code를 종료하세요 (/exit)"
  echo "  2. 다시 시작하세요"
  echo "  3. /setup 을 입력하여 초기화 위저드를 실행하세요"
  echo ""
  echo "재시작해야 스킬(/setup 등)이 인식됩니다."
else
  echo "======================================="
  echo " 설치 불완전 - 위 누락 항목을 확인하세요"
  echo "======================================="
  exit 1
fi
