# CLAUDE.md

## 이 프로젝트

- **이름**: dev-sys-template
- **설명**: Claude Code를 이용한 개발 환경 조성 템플릿
- **기술 스택**: Bash, YAML, Markdown
- **패키지 매니저**: 없음 (스크립트 기반)

## 컨텍스트 관리 규칙

- **계획 → 구현 전환 시**: 대화 히스토리에 의존하지 않는다. `docs/plans/{작업명}/`의 PLAN.md, CHECKLIST.md를 파일에서 다시 읽고 구현을 시작한다.
- **매 작업 시작 시**: CHECKLIST.md에서 현재 Phase의 세부 작업만 집중한다. Phase 단위로 나눠서 진행한다.
- **새 세션에서 이어서 작업할 때**: `docs/plans/`에서 `🟡 진행 중`인 CHECKLIST.md를 찾아 읽고, 미체크 항목부터 이어서 진행한다.

## 절대 금지 규칙

- **사용자가 계획을 승인하기 전에 코드를 작성하지 않는다.** 계획서를 보여준 뒤 사용자가 명시적으로 승인할 때까지 기다린다.
- **CHECKLIST.md 상태가 `🔴 시작 전`이면 미승인 상태다.** 승인 후에만 `🟡 진행 중`으로 변경하고 구현을 시작한다.
- **한 턴에 계획과 구현을 동시에 하지 않는다.**

## 계획 완료 후 새 요청 규칙

- 🟢 완료 후 새 코드 변경 요청이 오면, 아무리 간단해도 먼저 사용자에게 확인한다.
- "간단한 수정으로 보입니다. 바로 진행할까요, 아니면 /plan-manager로 새 계획을 수립할까요?" 를 반드시 물어본다.
- 이 규칙은 로고 변경, 텍스트 수정 등 1줄 변경에도 적용한다.
- 사용자가 "간단:" 접두사로 요청한 경우에만 즉시 진행한다.

## 필수 워크플로우 (이 순서를 반드시 따른다)

1. **계획 수립**: `/plan-manager`로 3문서 생성 → `docs/plans/{작업명}/`
2. **승인 대기**: 계획 요약을 보여주고 **반드시 사용자 응답을 기다린다**. 승인 후 CHECKLIST.md를 `🟡 진행 중`으로 변경.
3. **매뉴얼 참조**: `/dev-manual`로 작업 유형에 맞는 챕터를 읽는다
4. **구현**: 계획서의 Phase 순서대로 구현. CHECKLIST.md 실시간 업데이트.
5. **품질 검사**: Stop Hook이 자동 검사. 0건=통과, 1~3건=즉시수정, 4건+=서브에이전트 위임.

## Self-Hosting 구조

이 저장소는 자기 자신에게도 적용(dogfooding)하여 운영한다.

```
dev-sys/                        ← Claude Code CWD (git 없음)
├── .claude/                    ← 설치 사본 (sync로 갱신)
├── docs/                       ← 설치 사본 (plans/logs/reports는 보존)
├── CLAUDE.md                   ← 설치 사본
└── dev-system-template/        ← git root & 소스
    ├── .git/
    └── ...
```

### 편집 규칙
- 소스 수정은 반드시 `dev-system-template/` 안에서
- 수정 후 `bash dev-system-template/scripts/sync-to-parent.sh` 실행
- `dev-sys/.claude/`, `dev-sys/docs/`, `dev-sys/CLAUDE.md`를 직접 수정하지 않는다

## 프로젝트 구조

```
dev-system-template/
├── .claude/
│   ├── settings.json
│   ├── hooks/              ← Hook 스크립트 7개 + config.yml + lib/
│   ├── agents/             ← 서브에이전트 3개 (qa/test/planning)
│   └── skills/             ← 스킬 3개 (setup/plan-manager/dev-manual)
├── docs/
│   ├── logs/               ← 변경 로그
│   ├── plans/              ← 계획 3문서
│   └── reports/            ← 에이전트 보고서
├── scripts/                ← sync-to-parent.sh
├── CLAUDE.md
├── README.md
└── SETUP-GUIDE.md
```

## 코딩 규칙

- Shell 변수: UPPER_SNAKE_CASE
- 파일/디렉토리: kebab-case
- Hook 종료: exit 0 (통과) / exit 2 (차단)
- 차단 메시지는 stderr, 안내 메시지는 stdout

## 아키텍처

- config.yml → config-parser.sh → matcher.sh → 각 Hook 스크립트
- 의존성 방향: Hook → lib 방향만 허용

## 세팅 가능한 파일

- `.claude/hooks/config.yml` — Hook 동작 규칙
- `.claude/skills/dev-manual/chapters/` — 개발 매뉴얼 내용

## 서브에이전트

- **qa-agent**: 코드 검토, 오류 수정, 구조 개선
- **test-agent**: 기능 테스트, 오류 진단, 테스트 작성
- **planning-agent**: 계획 수립, 계획 검토, 문서 작성
