# 챕터 1: 프로젝트 개요

## 프로젝트

- **이름**: dev-sys-template
- **설명**: Claude Code를 이용한 개발 환경 조성 템플릿
- **기술 스택**: Bash, YAML, Markdown
- **패키지 매니저**: 없음 (스크립트 기반)

## 핵심 기능

1. `/setup` 위저드로 프로젝트 초기화
2. Hook 시스템으로 개발 프로세스 강제 (계획 → 승인 → 구현 루프)
3. 자동 품질 검사 및 서브에이전트 위임

## 디렉토리 구조

```
dev-system-template/        ← git root (GitHub 저장소)
├── .claude/
│   ├── settings.json       ← Hook 등록
│   ├── hooks/
│   │   ├── config.yml      ← 중앙 설정 (커스터마이징 포인트)
│   │   ├── lib/            ← 매칭 엔진 (config-parser.sh, matcher.sh)
│   │   └── *.sh            ← Hook 스크립트 7개
│   ├── agents/             ← 서브에이전트 3개 (qa/test/planning)
│   └── skills/             ← 스킬 3개 (setup/plan-manager/dev-manual)
├── docs/
│   ├── logs/               ← 변경 로그
│   ├── plans/              ← 계획 3문서
│   └── reports/            ← 에이전트 보고서
├── scripts/                ← 유틸리티 (sync-to-parent.sh)
├── CLAUDE.md
├── README.md
└── SETUP-GUIDE.md
```

## Self-Hosting 구조

이 저장소는 자기 자신에게도 적용(dogfooding)하여 운영한다.

```
dev-sys/                        ← Claude Code CWD (git 없음)
├── .claude/                    ← 설치 사본 (sync로 갱신)
├── docs/                       ← 설치 사본 (plans/logs/reports는 보존)
├── CLAUDE.md                   ← 설치 사본
└── dev-system-template/        ← git root & 소스
    ├── .git/
    └── ... (위 구조)
```

- 소스 수정은 `dev-system-template/` 안에서만
- `bash dev-system-template/scripts/sync-to-parent.sh`로 설치 사본 갱신

## 핵심 규칙

1. **파일 하나에 하나의 역할** — Hook 스크립트는 단일 이벤트만 처리
2. **config.yml이 모든 동작을 제어** — 스크립트 직접 수정 불필요
3. **매칭 엔진 4조건**: 키워드, 의도, 작업 위치, 파일 내용
