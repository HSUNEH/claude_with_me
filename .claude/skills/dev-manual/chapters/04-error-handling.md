# 챕터 4: 에러 처리

> [!NOTE]
> 이 파일은 템플릿입니다. 프로젝트 에러 처리 정책에 맞게 수정하세요.

## 에러 처리 원칙

1. **모든 외부 호출에 try-catch**: API, DB, 파일 I/O 등
2. **에러는 삼키지 말것**: catch에서 최소한 로깅 필수
3. **사용자 친화적 메시지**: 내부 에러를 그대로 노출하지 않기
4. **에러 경계 설정**: 컴포넌트 단위 ErrorBoundary 활용

## 에러 분류 체계

```typescript
// 커스텀 에러 클래스
class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 500,
    public isOperational: boolean = true
  ) {
    super(message);
  }
}

// 사용 예시
throw new AppError('사용자를 찾을 수 없습니다', 'USER_NOT_FOUND', 404);
```

## API 에러 응답 형식

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "이메일 형식이 올바르지 않습니다",
    "details": [
      { "field": "email", "message": "유효한 이메일을 입력하세요" }
    ]
  }
}
```

## 로깅 레벨

| 레벨 | 용도 | 예시 |
|------|------|------|
| ERROR | 즉시 대응 필요 | DB 연결 실패, 결제 오류 |
| WARN | 주의 필요 | 느린 쿼리, 재시도 성공 |
| INFO | 주요 흐름 기록 | 사용자 로그인, 주문 생성 |
| DEBUG | 디버깅용 (개발만) | 변수 값, 함수 호출 추적 |

## 필수 에러 처리 체크리스트

- [ ] 네트워크 요청에 타임아웃 설정했는가?
- [ ] 실패 시 재시도 로직이 필요한가?
- [ ] 사용자에게 적절한 에러 메시지를 보여주는가?
- [ ] 에러 로그에 충분한 컨텍스트가 포함되는가?
- [ ] 민감 정보가 에러 메시지에 노출되지 않는가?
