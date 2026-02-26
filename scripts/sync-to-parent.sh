#!/bin/bash
# dev-system-template 소스 → 상위 디렉토리 설치 사본으로 동기화
# self-hosting 환경에서 소스 수정 후 실행

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"
PARENT_DIR="$(dirname "$TEMPLATE_DIR")"

echo "소스: $TEMPLATE_DIR"
echo "대상: $PARENT_DIR"
echo ""

# .claude/ 동기화 (전체 덮어쓰기, 마커 파일 제외)
rsync -av --delete \
  --exclude='.initialized' \
  --exclude='.setup-in-progress' \
  "$TEMPLATE_DIR/.claude/" "$PARENT_DIR/.claude/"

# docs/ 동기화 (작업 산출물은 보존)
rsync -av --delete "$TEMPLATE_DIR/docs/" "$PARENT_DIR/docs/" \
  --exclude='logs/change-log.md' \
  --exclude='plans/' \
  --exclude='reports/'

# 실행 권한 설정
chmod +x "$PARENT_DIR/.claude/hooks/"*.sh "$PARENT_DIR/.claude/hooks/lib/"*.sh

# .initialized 마커 유지
touch "$PARENT_DIR/.claude/.initialized"

echo ""
echo "동기화 완료"
