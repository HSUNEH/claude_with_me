# setup.tape — /setup 위저드 5단계 시연
# Output: demos/assets/setup.gif

Source "common.tape"
Set Height 800

Output "../assets/setup.gif"

# bash 명령어 숨기고 실행
Hide
Type "bash ../mocks/demo-setup.sh"
Enter
Sleep 2s
Show

Sleep 30s

# 결과 확인 시간
Sleep 3s
