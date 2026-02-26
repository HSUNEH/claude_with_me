#!/bin/bash
# ============================================================
# [PostToolUse Hook] 체크리스트 자동 추적 리마인더
# ============================================================
# 역할: Edit/Write 도구로 파일 변경 후,
#       현재 진행 중인 CHECKLIST.md 업데이트를 상기시킨다.
#
# 동작: exit 0 + stdout → Claude 컨텍스트에 추가
# ============================================================

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# Edit, Write 도구에만 반응
if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
  exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
PLANS_DIR="$CWD/docs/plans"

# 계획 문서 자체를 수정하는 경우는 스킵
if echo "$FILE_PATH" | grep -q "docs/plans/"; then
  exit 0
fi

# 진행 중인 체크리스트 찾기
for checklist in "$PLANS_DIR"/*/CHECKLIST.md; do
  [ -f "$checklist" ] || continue
  if grep -q "🟡 진행 중" "$checklist" 2>/dev/null; then
    PLAN_DIR=$(dirname "$checklist")
    PLAN_NAME=$(basename "$PLAN_DIR")

    cat <<MSG
───────────────────────────────────────────
📝 [작업 기록] 파일 변경 감지
───────────────────────────────────────────
변경 파일: ${FILE_PATH}
진행 작업: ${PLAN_NAME}

→ docs/plans/${PLAN_NAME}/CHECKLIST.md 의
  변경 로그와 체크 항목을 업데이트하세요.
───────────────────────────────────────────
MSG
    break
  fi
done

exit 0
