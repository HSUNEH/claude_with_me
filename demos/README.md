# 데모 GIF 생성 가이드

이 디렉토리에는 README용 데모 GIF를 생성하기 위한 Mock 스크립트와 VHS 테이프 파일이 있습니다.

## 사전 준비

### 1. VHS 설치

```bash
# macOS
brew install charmbracelet/tap/vhs

# 또는 Go로 직접 설치
go install github.com/charmbracelet/vhs@latest
```

### 2. D2Coding 폰트 설치

한글 렌더링을 위해 [D2Coding](https://github.com/naver/d2codingfont) 폰트가 필요합니다.

```bash
# macOS (Homebrew)
brew install --cask font-d2coding
```

### 3. ttyd 설치 (VHS 의존성)

```bash
brew install ttyd
```

## GIF 생성

```bash
# 개별 생성
cd demos/tapes
vhs plan-guard.tape
vhs setup.tape
vhs quality-check.tape
vhs session-resume.tape
vhs hero.tape

# 전체 생성
for tape in demos/tapes/*.tape; do
  [[ "$(basename "$tape")" == "common.tape" ]] && continue
  vhs "$tape"
done
```

생성된 GIF는 `demos/assets/`에 저장됩니다.

## 파일 구조

```
demos/
├── README.md          ← 이 파일
├── assets/            ← 생성된 GIF 파일 (git 추적 제외)
│   └── .gitkeep
├── mocks/             ← Hook 출력 시뮬레이션 스크립트
│   ├── demo-plan-guard.sh
│   ├── demo-setup.sh
│   ├── demo-quality-check.sh
│   ├── demo-auto-manual.sh
│   └── demo-session-resume.sh
└── tapes/             ← VHS 테이프 파일
    ├── common.tape    ← 공통 설정 (Source용)
    ├── hero.tape      ← 전체 워크플로우 히어로
    ├── plan-guard.tape
    ├── setup.tape
    ├── quality-check.tape
    └── session-resume.tape
```

## Mock 스크립트 단독 실행

VHS 없이도 터미널에서 직접 확인할 수 있습니다:

```bash
bash demos/mocks/demo-plan-guard.sh
bash demos/mocks/demo-setup.sh
bash demos/mocks/demo-quality-check.sh
bash demos/mocks/demo-auto-manual.sh
bash demos/mocks/demo-session-resume.sh
```

## GIF 최적화

파일 크기가 너무 크면:

1. `common.tape`에서 `Set Framerate`를 10~12로 낮추기
2. Mock 스크립트에서 `sleep` 시간 단축
3. [gifsicle](https://www.lcdf.org/gifsicle/)로 후처리:
   ```bash
   gifsicle -O3 --lossy=80 input.gif -o output.gif
   ```

## 테마 변경

`common.tape`에서 `Set Theme`를 변경합니다. VHS 지원 테마 목록:

```bash
vhs themes
```
