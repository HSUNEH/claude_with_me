#!/bin/bash
# ============================================================
# 공통 매칭 유틸리티 — config.yml 기반 동작
# ============================================================
# 모든 매칭 규칙을 config.yml에서 읽어온다.
# config.yml이 없으면 내장 기본값으로 폴백한다.
#
# 사용법: source .claude/hooks/lib/matcher.sh
# ============================================================

# config 파서 로드
MATCHER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MATCHER_DIR/config-parser.sh"

# config 사용 가능 여부
_HAS_CONFIG=false
if _find_config >/dev/null 2>&1; then
  _HAS_CONFIG=true
fi


# ─── 1. 키워드 매칭 ─────────────────────────────────────────

match_keywords() {
  local TEXT="$1"

  if $_HAS_CONFIG; then
    for CATEGORY in dev test deploy docs; do
      local PATTERN=$(cfg_get_keywords "$CATEGORY")
      if [ -n "$PATTERN" ] && echo "$TEXT" | grep -qiE "$PATTERN"; then
        echo "$CATEGORY"
        return 0
      fi
    done
  else
    # 폴백: 내장 기본값
    if echo "$TEXT" | grep -qiE '만들|개발|수정|추가|삭제|리팩토링|구현|생성|변경|합[쳐치]|병합|넣[어고]|붙[여이]|옮[기겨]|분리|나[누눠]|fix|create|add|update|delete|refactor|implement|build|merge|split|move'; then echo "dev"; return 0; fi
    if echo "$TEXT" | grep -qiE '테스트|검증|확인|test|verify|check|spec'; then echo "test"; return 0; fi
    if echo "$TEXT" | grep -qiE '배포|deploy|release|publish|docker'; then echo "deploy"; return 0; fi
    if echo "$TEXT" | grep -qiE '문서|작성|readme|doc|설명|가이드'; then echo "docs"; return 0; fi
  fi

  echo "none"
  return 1
}


# ─── 2. 의도 파악 ───────────────────────────────────────────

# 의도 목록: config.yml에서 동적으로 읽고, 없으면 기본값 사용
_INTENT_ORDER_DEFAULT="new_feature bugfix refactor api security test docs"

_get_intent_order() {
  if $_HAS_CONFIG; then
    local FROM_CONFIG=$(cfg_list_intents)
    if [ -n "$FROM_CONFIG" ]; then
      echo "$FROM_CONFIG"
      return
    fi
  fi
  echo "$_INTENT_ORDER_DEFAULT"
}

detect_intent() {
  local TEXT="$1"
  local INTENT_ORDER=$(_get_intent_order)

  for INTENT in $INTENT_ORDER; do
    local PATTERN=""
    if $_HAS_CONFIG; then
      PATTERN=$(cfg_get_intent_field "$INTENT" "patterns")
    fi

    # config에서 못 읽으면 내장 기본값
    if [ -z "$PATTERN" ]; then
      case "$INTENT" in
        new_feature) PATTERN="(새로운|새 |신규).*(기능|페이지|컴포넌트|모듈|API)|추가[해하할]|만들[어고]|구현[해하]|넣[어고]|생성[해하]|붙[여이]|create|implement|add new|add .*to" ;;
        bugfix)      PATTERN="버그|오류|에러|안 ?됨|안 ?돼|수정[해하]|고[쳐치]|fix|bug|error|broken|not working" ;;
        refactor)    PATTERN="리팩토링|정리[해하]?|개선[해하]?|최적화|성능|합[쳐치]|병합[해하]?|분리[해하]?|나[누눠]|옮[기겨]|refactor|clean ?up|optimize|improve|simplify|merge|split|move" ;;
        api)         PATTERN="api|엔드포인트|endpoint|라우트|route|요청|request|응답|response|REST|GraphQL" ;;
        security)    PATTERN="보안|인증|권한|토큰|암호|security|auth|token|permission|encrypt" ;;
        test)        PATTERN="테스트|test|spec|검증|커버리지|coverage" ;;
        docs)        PATTERN="문서|doc|readme|가이드|설명서|주석|comment" ;;
        *)           ;; # 커스텀 의도: config.yml에 patterns가 없으면 스킵
      esac
    fi

    if [ -n "$PATTERN" ] && echo "$TEXT" | grep -qiE "$PATTERN"; then
      echo "$INTENT"
      return 0
    fi
  done

  echo "unknown"
  return 1
}

# 의도의 계획 필수 여부
intent_requires_plan() {
  local INTENT="$1"

  if $_HAS_CONFIG; then
    local VAL=$(cfg_get_intent_field "$INTENT" "require_plan")
    if [ "$VAL" = "false" ]; then
      return 1  # 계획 불필요
    fi
  else
    # 기본: test, docs는 계획 불필요
    if [ "$INTENT" = "test" ] || [ "$INTENT" = "docs" ]; then
      return 1
    fi
  fi
  return 0  # 계획 필요
}

# 의도 한글 라벨
intent_to_label() {
  local INTENT="$1"

  if $_HAS_CONFIG; then
    local LABEL=$(cfg_get_intent_field "$INTENT" "label")
    if [ -n "$LABEL" ]; then echo "$LABEL"; return; fi
  fi

  case "$INTENT" in
    new_feature) echo "새 기능 개발" ;;
    bugfix)      echo "버그 수정" ;;
    refactor)    echo "리팩토링" ;;
    api)         echo "API 작업" ;;
    security)    echo "보안 작업" ;;
    test)        echo "테스트 작업" ;;
    docs)        echo "문서 작업" ;;
    *)           echo "일반 개발" ;;
  esac
}


# ─── 3. 작업 위치 ───────────────────────────────────────────

# 위치 목록: config.yml에서 동적으로 읽고, 없으면 기본값 사용
_LOCATION_ORDER_DEFAULT="ui api service db config test style"

_get_location_order() {
  if $_HAS_CONFIG; then
    local FROM_CONFIG=$(cfg_list_locations)
    if [ -n "$FROM_CONFIG" ]; then
      echo "$FROM_CONFIG"
      return
    fi
  fi
  echo "$_LOCATION_ORDER_DEFAULT"
}

detect_location() {
  local FILE_PATH="$1"
  local LOCATION_ORDER=$(_get_location_order)

  for LOC in $LOCATION_ORDER; do
    local PATTERN=""
    if $_HAS_CONFIG; then
      PATTERN=$(cfg_get_location_field "$LOC" "patterns")
    fi

    if [ -z "$PATTERN" ]; then
      case "$LOC" in
        ui)      PATTERN="(components?|pages?|views?|layouts?|app)/.*\.(tsx?|jsx?|vue|svelte)" ;;
        api)     PATTERN="(api|routes?|controllers?|handlers?)/" ;;
        service) PATTERN="(services?|lib|utils?|helpers?|hooks)/" ;;
        db)      PATTERN="(models?|schema|migration|prisma|drizzle|database|db)/" ;;
        config)  PATTERN="(config|\.env|tsconfig|package\.json|next\.config|vite\.config)" ;;
        test)    PATTERN="(tests?|__tests__|spec|\.test\.|\.spec\.)" ;;
        style)   PATTERN="\.(css|scss|sass|less|styled)" ;;
        *)       ;; # 커스텀 위치: config.yml에 patterns가 없으면 스킵
      esac
    fi

    if [ -n "$PATTERN" ] && echo "$FILE_PATH" | grep -qiE "$PATTERN"; then
      echo "$LOC"
      return 0
    fi
  done

  echo "unknown"
  return 1
}


# ─── 4. 코드 패턴 감지 ──────────────────────────────────────

detect_code_patterns() {
  local FILE_PATH="$1"
  [ ! -f "$FILE_PATH" ] && return 1

  local ISSUES=""

  if $_HAS_CONFIG; then
    # config에서 패턴 읽기
    for NAME in security_dangerous_functions security_hardcoded_secrets type_any_usage debug_leftover; do
      local PATTERN=$(cfg_get_code_pattern "$NAME" "pattern")
      local MSG=$(cfg_get_code_pattern "$NAME" "message")
      local DO_COUNT=$(cfg_get_code_pattern "$NAME" "count")

      if [ -n "$PATTERN" ] && grep -qnE "$PATTERN" "$FILE_PATH" 2>/dev/null; then
        if [ "$DO_COUNT" = "true" ]; then
          local CNT=$(grep -cnE "$PATTERN" "$FILE_PATH" 2>/dev/null)
          ISSUES="${ISSUES}${MSG} (${CNT}건)\n"
        else
          ISSUES="${ISSUES}${MSG}\n"
        fi
      fi
    done

    # dual 체크 (존재 + 부재)
    local MUST_EXIST=$(cfg_get_code_pattern "error_missing_catch" "must_exist")
    local MUST_NOT=$(cfg_get_code_pattern "error_missing_catch" "must_not_exist")
    local MSG=$(cfg_get_code_pattern "error_missing_catch" "message")
    if [ -n "$MUST_EXIST" ] && grep -qnE "$MUST_EXIST" "$FILE_PATH" 2>/dev/null; then
      if [ -n "$MUST_NOT" ] && ! grep -qnE "$MUST_NOT" "$FILE_PATH" 2>/dev/null; then
        ISSUES="${ISSUES}${MSG}\n"
      fi
    fi
  else
    # 폴백: 내장 기본값
    if grep -qnE '(eval\(|innerHTML|dangerouslySetInnerHTML|exec\(|\.raw\()' "$FILE_PATH" 2>/dev/null; then
      ISSUES="${ISSUES}[보안] 위험 함수 사용 감지 (eval/innerHTML/exec)\n"
    fi
    if grep -qnE '(password|secret|api_key|apikey|token|credential)\s*[:=]\s*["'"'"'][^"'"'"']' "$FILE_PATH" 2>/dev/null; then
      ISSUES="${ISSUES}[보안] 하드코딩된 비밀정보 의심\n"
    fi
    if grep -qnE '(await |\.then\()' "$FILE_PATH" 2>/dev/null; then
      if ! grep -qnE '(try\s*\{|\.catch\(|catch\s*\()' "$FILE_PATH" 2>/dev/null; then
        ISSUES="${ISSUES}[에러처리] 비동기 호출에 try-catch/catch 누락 의심\n"
      fi
    fi
    if grep -qnE ':\s*any\b' "$FILE_PATH" 2>/dev/null; then
      local COUNT=$(grep -cnE ':\s*any\b' "$FILE_PATH" 2>/dev/null)
      ISSUES="${ISSUES}[타입] any 타입 ${COUNT}건 사용 감지\n"
    fi
    if grep -qnE '(console\.(log|debug|warn)|debugger|TODO|FIXME|HACK|XXX)' "$FILE_PATH" 2>/dev/null; then
      ISSUES="${ISSUES}[정리] 디버그 코드/TODO 잔류 감지\n"
    fi
  fi

  if [ -n "$ISSUES" ]; then
    echo -e "$ISSUES"
    return 0
  fi
  return 1
}


# ─── 매핑 헬퍼 ──────────────────────────────────────────────

intent_to_chapters() {
  local INTENT="$1"

  if $_HAS_CONFIG; then
    local CHAPTERS=$(cfg_get_intent_field "$INTENT" "chapters")
    if [ -n "$CHAPTERS" ]; then echo "$CHAPTERS"; return; fi
  fi

  case "$INTENT" in
    new_feature) echo "1(프로젝트 개요), 2(코딩 표준), 3(아키텍처)" ;;
    bugfix)      echo "1(프로젝트 개요), 4(에러 처리)" ;;
    refactor)    echo "2(코딩 표준), 3(아키텍처)" ;;
    api)         echo "2(코딩 표준), 3(아키텍처), 4(에러 처리), 5(보안)" ;;
    security)    echo "5(보안), 4(에러 처리)" ;;
    test)        echo "6(테스트)" ;;
    docs)        echo "1(프로젝트 개요)" ;;
    *)           echo "1(프로젝트 개요)" ;;
  esac
}

location_to_label() {
  local LOC="$1"

  if $_HAS_CONFIG; then
    local LABEL=$(cfg_get_location_field "$LOC" "label")
    if [ -n "$LABEL" ]; then echo "$LABEL"; return; fi
  fi

  case "$LOC" in
    ui)      echo "UI/프론트엔드" ;;
    api)     echo "API/라우트" ;;
    service) echo "서비스/로직" ;;
    db)      echo "DB/모델" ;;
    config)  echo "설정 파일" ;;
    test)    echo "테스트" ;;
    style)   echo "스타일" ;;
    *)       echo "일반" ;;
  esac
}

location_to_focus() {
  local LOC="$1"

  if $_HAS_CONFIG; then
    local FOCUS=$(cfg_get_location_field "$LOC" "focus")
    if [ -n "$FOCUS" ]; then echo "$FOCUS"; return; fi
  fi

  case "$LOC" in
    ui)      echo "XSS 방지, 접근성, 상태 관리, 렌더링 성능" ;;
    api)     echo "입력 검증, 인증/인가, Rate Limiting, 에러 응답 형식" ;;
    service) echo "에러 처리, 엣지 케이스, 타입 안전성, 단위 테스트" ;;
    db)      echo "SQL Injection 방지, 마이그레이션 안전성, 인덱스" ;;
    config)  echo "환경변수 노출, 호환성, 기본값 설정" ;;
    test)    echo "커버리지, 엣지 케이스, 비동기 처리, Mock 정확성" ;;
    style)   echo "반응형, 접근성, 성능 (불필요한 CSS)" ;;
    *)       echo "일반 코드 품질, 네이밍, 에러 처리" ;;
  esac
}

# 위치별 체크리스트 (config에서 읽거나 기본값)
location_to_checklist() {
  local LOC="$1"

  if $_HAS_CONFIG; then
    local ITEMS=$(cfg_get_checklist "$LOC")
    if [ -n "$ITEMS" ]; then
      echo "$ITEMS" | while read -r item; do
        echo "□ $item"
      done
      return
    fi
  fi

  # 기본값
  case "$LOC" in
    ui)
      echo "□ XSS: 사용자 입력을 innerHTML로 렌더링하지 않는가?"
      echo "□ 접근성: aria 속성, 키보드 네비게이션 고려했는가?"
      echo "□ 상태: 불필요한 리렌더링은 없는가?"
      ;;
    api)
      echo "□ 입력 검증: 모든 요청 파라미터를 검증하는가?"
      echo "□ 인증/인가: 적절한 미들웨어가 적용되어 있는가?"
      echo "□ 에러 응답: 통일된 형식으로 에러를 반환하는가?"
      ;;
    db)
      echo "□ SQL Injection: 파라미터 바인딩을 사용하는가?"
      echo "□ 마이그레이션: 롤백 가능한 구조인가?"
      ;;
    *)
      echo "□ 위험한 부분은 없는가?"
      echo "□ 에러 처리를 추가했는가?"
      echo "□ 보안은 괜찮은가?"
      echo "□ 빠뜨린 건 없는가?"
      ;;
  esac
}

# 완료 검사 임계값
get_threshold_immediate() {
  if $_HAS_CONFIG; then
    local VAL=$(cfg_get_threshold "threshold_immediate_fix")
    if [ -n "$VAL" ]; then echo "$VAL"; return; fi
  fi
  echo "3"
}

get_threshold_agent() {
  if $_HAS_CONFIG; then
    local VAL=$(cfg_get_threshold "threshold_agent_recommend")
    if [ -n "$VAL" ]; then echo "$VAL"; return; fi
  fi
  echo "4"
}
