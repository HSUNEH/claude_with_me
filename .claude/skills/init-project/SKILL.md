---
name: init-project
description: 개발 시스템 초기 세팅. 프로젝트 정보를 수집하여 config.yml과 매뉴얼 챕터를 자동 생성한다. 템플릿 적용 후 최초 1회 실행.
---

# 프로젝트 초기 세팅

이 스킬은 개발 시스템 템플릿을 새 프로젝트에 적용할 때 **최초 1회** 실행한다.
사용자에게 프로젝트 정보를 질문하고, 답변을 기반으로 설정 파일과 매뉴얼을 자동 생성한다.

---

## 실행 절차

### Phase 1: 프로젝트 기본 정보 수집

사용자에게 다음을 **순서대로** 질문한다. 이미 프로젝트 코드가 존재하면 먼저 분석하여 자동 감지한 내용을 보여주고 확인받는다.

**Q1. 프로젝트 개요**
- 프로젝트명
- 한 줄 설명 (이 프로젝트가 뭘 하는 건지)
- 현재 상태 (신규 시작 / 기존 프로젝트에 적용)

**Q2. 기술 스택**
- 언어 (TypeScript, JavaScript, Python, Go 등)
- 프레임워크 (Next.js, React, FastAPI, Express 등)
- DB (PostgreSQL, MongoDB, MySQL, SQLite 등 — 없으면 없음)
- ORM/쿼리빌더 (Prisma, Drizzle, SQLAlchemy, TypeORM 등 — 없으면 없음)
- 패키지 매니저 (npm, yarn, pnpm, pip, poetry 등)

**Q3. 프로젝트 구조**
- 주요 디렉토리 구조 (src/, app/, pages/, components/ 등)
- 모노레포 여부
- 특이한 구조가 있으면 설명

**Q4. 코딩 규칙**
- 린터/포매터 (ESLint, Prettier, Ruff, Black 등)
- 네이밍 규칙 (camelCase, snake_case 등)
- import 순서 규칙 (있다면)
- 특별한 코딩 컨벤션 (있다면)

**Q5. 에러 처리 & 보안**
- 에러 처리 패턴 (커스텀 에러 클래스, Result 패턴 등)
- 인증 방식 (JWT, Session, OAuth 등)
- 특별한 보안 규칙 (있다면)

**Q6. 테스트**
- 테스트 프레임워크 (Jest, Vitest, Pytest, Go test 등)
- 테스트 디렉토리 위치
- 최소 커버리지 기준 (있다면)

---

### Phase 2: 기존 코드 자동 분석 (기존 프로젝트인 경우)

Q1에서 "기존 프로젝트에 적용"이라고 답한 경우, 질문 전에 먼저 자동 분석을 실행한다:

```
분석 항목:
1. package.json / pyproject.toml / go.mod 등 → 기술 스택 자동 감지
2. 디렉토리 구조 → locations 패턴 자동 추출
3. .eslintrc / prettier / ruff.toml 등 → 린터 설정 감지
4. tsconfig.json → TypeScript 설정 감지
5. 기존 테스트 파일 패턴 → 테스트 프레임워크 감지
6. 기존 코드 패턴 → 네이밍 규칙, import 순서 추론
```

분석 결과를 사용자에게 보여주고:
- "이렇게 감지됐는데 맞나요?"
- 틀린 부분만 수정하도록 안내

---

### Phase 3: config.yml 자동 생성

수집한 정보를 바탕으로 `.claude/hooks/config.yml`을 프로젝트에 맞게 덮어쓴다.

#### 매핑 규칙

**keywords**: 기술 스택에 맞는 키워드 추가
- React → "컴포넌트|훅|상태|렌더링|component|hook|state"
- API → "엔드포인트|라우트|미들웨어|endpoint|route|middleware"
- Python → "클래스|함수|데코레이터|class|def|decorator"

**intents**: 기본 7개 유지 + 프로젝트 특성에 맞는 의도 추가
- DB 사용 시 → migration 의도 추가
- 모노레포 시 → package 의도 추가

**locations**: 실제 디렉토리 구조에 맞게 패턴 수정
- Q3 답변의 디렉토리 구조를 그대로 반영
- 예: `app/` 구조면 → ui patterns를 `app/` 기준으로 변경

**code_patterns**: 기술 스택에 맞는 패턴 추가
- React → useEffect cleanup 체크, key prop 체크
- Python → bare except 체크, f-string 보안 체크
- Go → error 무시 체크, defer 누락 체크

**completion_check.linters**: 실제 사용하는 린터만 활성화
- ESLint 없으면 → javascript.enabled: false
- Python 프로젝트면 → python에 ruff 또는 mypy 설정

**agents**: 기본 3개 유지 (변경 불필요)

---

### Phase 4: 매뉴얼 챕터 자동 생성

수집한 정보를 바탕으로 6개 챕터 파일을 생성한다.

| 챕터 | 사용하는 정보 |
|------|---------------|
| 01-project-overview.md | Q1 (프로젝트명, 설명, 상태) + Q2 (기술 스택) + Q3 (구조) |
| 02-coding-standards.md | Q4 (코딩 규칙) + Q2 (언어/프레임워크별 관례) |
| 03-architecture.md | Q3 (프로젝트 구조) + Q2 (프레임워크 아키텍처 패턴) |
| 04-error-handling.md | Q5 (에러 처리 패턴) + Q2 (프레임워크별 에러 처리) |
| 05-security.md | Q5 (보안 규칙) + Q2 (프레임워크별 보안 가이드) |
| 06-testing.md | Q6 (테스트 정보) + Q2 (프레임워크별 테스트 패턴) |

#### 챕터 작성 규칙

- **구체적으로** 작성 — "에러를 잘 처리하세요" (X) → "AppError 클래스를 사용하여 에러 코드와 메시지를 반환" (O)
- **코드 예시 포함** — 각 챕터에 해당 프로젝트 기술 스택에 맞는 코드 예시를 넣는다
- **DO / DON'T** — 각 규칙에 올바른 예시와 잘못된 예시를 함께 넣는다
- **기존 코드 참조** — 기존 프로젝트면 실제 코드에서 좋은 패턴을 발견하여 예시로 활용

---

### Phase 5: 완료 마커 생성 & 확인

모든 파일 생성이 끝나면 초기화 완료 마커를 생성한다:

```bash
touch .claude/.initialized
```

이 마커가 있으면 pre-prompt-check 훅이 더 이상 초기 세팅 안내를 표시하지 않는다.

그리고 사용자에게 결과를 보여준다:

```
✅ 초기 세팅 완료!

📄 생성/수정된 파일:
  .claude/hooks/config.yml     ← 프로젝트 맞춤 설정
  .claude/skills/dev-manual/chapters/
    01-project-overview.md     ← 프로젝트 개요
    02-coding-standards.md     ← 코딩 표준
    03-architecture.md         ← 아키텍처
    04-error-handling.md       ← 에러 처리
    05-security.md             ← 보안
    06-testing.md              ← 테스트

🔍 확인해주세요:
  1. config.yml의 키워드/경로 패턴이 맞는지
  2. 각 챕터 내용이 프로젝트 규칙과 일치하는지
  3. 수정할 부분이 있으면 말씀해주세요

이제 "새 기능 만들어줘" 같은 개발 지시를 하면
계획 수립부터 품질 검사까지 자동으로 작동합니다.
```

---

## 재실행

이미 세팅된 프로젝트에서 다시 실행하면:
- 기존 config.yml과 챕터를 백업 (`.bak` 접미사)
- 새로 생성
- 차이점을 보여주고 어떤 버전을 쓸지 물어봄
