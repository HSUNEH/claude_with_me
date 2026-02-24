# 챕터 2: 코딩 표준

> [!NOTE]
> 이 파일은 템플릿입니다. 프로젝트 규칙에 맞게 수정하세요.

## 네이밍 컨벤션

| 대상 | 규칙 | 예시 |
|------|------|------|
| 변수/함수 | camelCase | `getUserData`, `isActive` |
| 컴포넌트 | PascalCase | `UserProfile`, `MainLayout` |
| 상수 | UPPER_SNAKE | `MAX_RETRY_COUNT`, `API_BASE_URL` |
| 파일(컴포넌트) | PascalCase | `UserProfile.tsx` |
| 파일(유틸) | camelCase | `formatDate.ts` |
| 타입/인터페이스 | PascalCase + 접두사 | `IUserProps`, `TApiResponse` |

## 코드 스타일

- 들여쓰기: 스페이스 2칸
- 세미콜론: 사용
- 따옴표: 작은따옴표 (`'`)
- 최대 줄 길이: 100자
- 후행 쉼표: 항상 사용

## 함수 작성 규칙

```typescript
// GOOD: 명확한 이름, 타입 명시, JSDoc
/** 사용자 데이터를 ID로 조회한다 */
async function getUserById(userId: string): Promise<User> {
  // ...
}

// BAD: 모호한 이름, 타입 누락
async function getData(id) {
  // ...
}
```

## 금지 패턴

- `any` 타입 사용 금지 (불가피한 경우 `unknown` 사용)
- `console.log` 프로덕션 코드에 남기기 금지
- 매직 넘버 사용 금지 → 상수로 추출
- 중첩 삼항 연산자 금지
