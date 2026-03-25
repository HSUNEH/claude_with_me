---
name: dev-manual
description: "프로젝트 개발 매뉴얼. 작업 유형별 관련 챕터를 선택적으로 읽어 토큰을 절약한다."
user-invocable: true
allowed-tools: Read, Grep, Glob
---

# 개발 매뉴얼

> **전체를 읽지 말고, 현재 작업에 해당하는 챕터만 선택적으로 읽어 토큰을 절약하세요.**

## 목차

| 챕터 | 파일 | 내용 |
|------|------|------|
| 1 | `.cwm/dev-manual/chapters/01-project-overview.md` | 프로젝트 구조, 기술 스택 |
| 2 | `.cwm/dev-manual/chapters/02-coding-standards.md` | 네이밍, 코드 스타일 |
| 3 | `.cwm/dev-manual/chapters/03-architecture.md` | 아키텍처, 모듈 구조 |
| 4 | `.cwm/dev-manual/chapters/04-error-handling.md` | 에러 처리, 로깅 |
| 5 | `.cwm/dev-manual/chapters/05-security.md` | 보안, 인증/인가 |
| 6 | `.cwm/dev-manual/chapters/06-testing.md` | 테스트 전략, 커버리지 |

## 챕터 선택 가이드

```
작업 유형별 읽을 챕터:
├── 새 기능 개발     → 1, 2, 3
├── 버그 수정        → 1, 4
├── API 개발         → 2, 3, 4, 5
├── 리팩토링         → 2, 3
├── 테스트 작성      → 6
└── 보안 관련 작업   → 5, 4
```

## 사용법

1. **작업 시작 시**: 챕터 1(프로젝트 개요) 확인
2. **코드 작성 시**: 챕터 2(코딩 표준) + 해당 도메인 챕터
3. **완료 시**: 챕터 4(에러처리) + 5(보안) 기준 셀프체크

## 챕터 파일 위치

`/cwm:setupwithme` 실행 시 프로젝트에 맞게 자동 생성됩니다.
위치: `.cwm/dev-manual/chapters/`
