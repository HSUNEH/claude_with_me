# 챕터 1: 프로젝트 개요

> [!NOTE]
> 이 파일은 템플릿입니다. 실제 프로젝트에 맞게 내용을 채워주세요.

## 기술 스택

- **언어**: (예: TypeScript 5.x)
- **프레임워크**: (예: Next.js 14)
- **DB**: (예: PostgreSQL + Prisma)
- **상태관리**: (예: Zustand)
- **패키지 매니저**: (예: pnpm)

## 디렉토리 구조

```
project-root/
├── src/
│   ├── app/          # 라우팅 & 페이지
│   ├── components/   # UI 컴포넌트
│   ├── lib/          # 유틸리티 & 헬퍼
│   ├── services/     # 비즈니스 로직
│   ├── types/        # 타입 정의
│   └── hooks/        # 커스텀 훅
├── tests/            # 테스트 파일
├── docs/             # 문서
└── scripts/          # 빌드/배포 스크립트
```

## 핵심 규칙

1. **단일 책임 원칙**: 파일 하나에 하나의 역할만
2. **절대 경로 사용**: `@/` alias 기반 import
3. **환경 변수**: `.env.local`에서 관리, 코드에 하드코딩 금지

## 의존성 설치 명령

```bash
# 의존성 설치
pnpm install

# 개발 서버 실행
pnpm dev

# 빌드
pnpm build
```
