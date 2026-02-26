---
name: dev-manual
description: "프로젝트 개발 매뉴얼. 모든 작업 시작 전 반드시 참조해야 하는 개발 가이드라인. 코딩 표준, 아키텍처, 에러처리, 보안, 테스트 규칙을 담고 있다."
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Grep, Glob
---

# 개발 매뉴얼

> 이 매뉴얼은 프로젝트의 모든 개발 규칙을 담고 있습니다.
> **전체를 읽지 말고, 현재 작업에 해당하는 챕터만 선택적으로 읽어 토큰을 절약하세요.**

## 목차

| 챕터 | 파일 | 내용 요약 |
|------|------|-----------|
| 1 | [chapters/01-project-overview.md](chapters/01-project-overview.md) | 프로젝트 구조, 기술 스택, 디렉토리 규칙 |
| 2 | [chapters/02-coding-standards.md](chapters/02-coding-standards.md) | 네이밍 컨벤션, 코드 스타일, 포맷팅 규칙 |
| 3 | [chapters/03-architecture.md](chapters/03-architecture.md) | 아키텍처 패턴, 모듈 구조, 의존성 규칙 |
| 4 | [chapters/04-error-handling.md](chapters/04-error-handling.md) | 에러 처리 패턴, 로깅, 예외 전략 |
| 5 | [chapters/05-security.md](chapters/05-security.md) | 보안 체크리스트, 인증/인가, 데이터 보호 |
| 6 | [chapters/06-testing.md](chapters/06-testing.md) | 테스트 전략, 커버리지 기준, 테스트 작성법 |

## 사용법

1. **새 작업 시작 시**: 챕터 1(프로젝트 개요) 확인
2. **코드 작성 시**: 챕터 2(코딩 표준) + 해당 도메인 챕터 참조
3. **작업 완료 시**: 챕터 4(에러처리) + 챕터 5(보안) 기준으로 셀프체크

## 챕터 선택 가이드

```
작업 유형에 따라 읽을 챕터:
├── 새 기능 개발     → 1, 2, 3
├── 버그 수정        → 1, 4
├── API 개발         → 2, 3, 4, 5
├── 리팩토링         → 2, 3
├── 테스트 작성      → 6
└── 보안 관련 작업   → 5, 4
```
