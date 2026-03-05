# setup.tape — /setup 위저드 시연 (Phase별 사용자 응답 포함)
Source "common.tape"
Set Height 750
Output "../assets/setup.gif"

Hide
Type "bash ../mocks/demo-setup.sh"
Enter
Sleep 1.5s
Show
Sleep 23s
Sleep 0.5s
