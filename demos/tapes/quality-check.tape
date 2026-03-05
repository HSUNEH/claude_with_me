# quality-check.tape — 자동 품질 검사 시연
# Output: demos/assets/quality-check.gif

Source "common.tape"
Set Height 700

Output "../assets/quality-check.gif"

# bash 명령어 숨기고 실행
Hide
Type "bash ../mocks/demo-quality-check.sh"
Enter
Sleep 2s
Show

Sleep 15s

# 결과 확인 시간
Sleep 3s
