#!/bin/bash
# ============================================================
# [SubagentStop Hook] 서브에이전트 완료 후 보고서 확인
# ============================================================
# 서브에이전트가 작업을 마친 뒤 보고서를 제대로 작성했는지 확인한다.
# ============================================================

INPUT=$(cat)
AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# 에이전트명이 없으면 스킵
if [ -z "$AGENT_NAME" ]; then
  exit 0
fi

REPORTS_DIR="$CWD/docs/reports"
TODAY=$(date +%Y-%m-%d)

# 에이전트별 보고서 파일명 패턴
case "$AGENT_NAME" in
  qa-agent)
    REPORT_PATTERN="qa-report"
    AGENT_LABEL="품질관리"
    ;;
  test-agent)
    REPORT_PATTERN="test-report"
    AGENT_LABEL="테스트"
    ;;
  planning-agent)
    REPORT_PATTERN="planning-report"
    AGENT_LABEL="기획"
    ;;
  *)
    exit 0
    ;;
esac

# 오늘 날짜의 보고서가 있는지 확인
REPORT_FILE=$(ls "$REPORTS_DIR"/${REPORT_PATTERN}-${TODAY}*.md 2>/dev/null | head -1)

if [ -n "$REPORT_FILE" ]; then
  # 보고서 존재 → 요약 표시
  LINE_COUNT=$(wc -l < "$REPORT_FILE")
  cat <<MSG
───────────────────────────────────────────
📊 [${AGENT_LABEL} 에이전트] 보고서 작성 완료
───────────────────────────────────────────
보고서: ${REPORT_FILE}
분량: ${LINE_COUNT}줄

보고서를 확인하고 후속 조치를 진행하세요.
───────────────────────────────────────────
MSG
else
  # 보고서 미작성 → 경고
  cat <<MSG
───────────────────────────────────────────
⚠️ [${AGENT_LABEL} 에이전트] 보고서 미작성
───────────────────────────────────────────
${AGENT_NAME}이 보고서를 작성하지 않았습니다.
예상 위치: ${REPORTS_DIR}/${REPORT_PATTERN}-${TODAY}.md

에이전트의 중요 규칙: "보고서 없는 작업은 미완료"
보고서 작성을 요청하세요.
───────────────────────────────────────────
MSG
fi

exit 0
