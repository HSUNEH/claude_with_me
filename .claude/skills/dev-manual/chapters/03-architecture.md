# 챕터 3: 아키텍처

> [!NOTE]
> 이 파일은 템플릿입니다. 프로젝트 아키텍처에 맞게 수정하세요.

## 레이어 구조

```
[UI Layer]  →  [Service Layer]  →  [Data Layer]
컴포넌트        비즈니스 로직        API/DB 호출
```

## 의존성 방향

- UI → Service → Data (단방향만 허용)
- 역방향 의존 금지
- 순환 의존 금지

## 모듈 설계 원칙

1. **인터페이스 우선**: 구현 전 타입/인터페이스 먼저 정의
2. **느슨한 결합**: 모듈 간 직접 참조 최소화, DI 패턴 활용
3. **응집도 유지**: 관련 기능은 같은 모듈에, 관련 없는 기능은 분리

## API 설계 규칙

- RESTful 컨벤션 준수
- 응답 형식 통일: `{ success: boolean, data?: T, error?: string }`
- 버전 관리: `/api/v1/` 접두사
- 페이지네이션: cursor 기반 권장

## 상태 관리

- 서버 상태: React Query / SWR
- 클라이언트 상태: Zustand / Context
- 폼 상태: React Hook Form
- URL 상태: searchParams 활용
