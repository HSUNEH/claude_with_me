# 챕터 6: 테스트

> [!NOTE]
> 이 파일은 템플릿입니다. 프로젝트 테스트 전략에 맞게 수정하세요.

## 테스트 전략

```
테스트 피라미드:
     /  E2E  \          ← 최소 (핵심 플로우만)
    / 통합 테스트 \       ← 적정 (API, DB 연동)
   / 단위 테스트     \    ← 최대 (모든 비즈니스 로직)
```

## 테스트 파일 규칙

- 위치: 소스 파일과 동일 디렉토리 또는 `__tests__/`
- 네이밍: `*.test.ts` 또는 `*.spec.ts`
- 하나의 테스트 파일 = 하나의 소스 파일

## 테스트 작성 패턴

```typescript
describe('getUserById', () => {
  // Given-When-Then 패턴
  it('존재하는 사용자 ID로 조회하면 사용자를 반환한다', async () => {
    // Given (준비)
    const mockUser = { id: '1', name: 'Kim' };
    mockDb.findById.mockResolvedValue(mockUser);

    // When (실행)
    const result = await getUserById('1');

    // Then (검증)
    expect(result).toEqual(mockUser);
  });

  it('존재하지 않는 ID로 조회하면 NotFoundError를 던진다', async () => {
    mockDb.findById.mockResolvedValue(null);
    await expect(getUserById('999')).rejects.toThrow(NotFoundError);
  });
});
```

## 커버리지 기준

| 대상 | 최소 커버리지 |
|------|-------------|
| 비즈니스 로직 | 80% |
| 유틸리티 함수 | 90% |
| API 엔드포인트 | 70% |
| UI 컴포넌트 | 60% |

## 테스트 필수 항목

- [ ] 정상 케이스 (happy path)
- [ ] 에러 케이스 (예외, 실패)
- [ ] 경계값 (빈 값, null, 최대/최소)
- [ ] 비동기 처리 (타임아웃, 동시성)
