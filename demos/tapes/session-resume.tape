# session-resume.tape — 세션 이어가기 시연
# Output: demos/assets/session-resume.gif

Source "common.tape"
Set Height 650

Output "../assets/session-resume.gif"

# bash 명령어 숨기고 실행
Hide
Type "bash ../mocks/demo-session-resume.sh"
Enter
Sleep 2s
Show

Sleep 15s

# 결과 확인 시간
Sleep 3s
