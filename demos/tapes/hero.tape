# hero.tape — 4개 시나리오 핵심 장면 조합
Source "common.tape"
Set Height 700
Output "../assets/hero.gif"

# Scene 1: 계획 모드
Hide
Type "bash ../mocks/demo-plan-mode.sh"
Enter
Sleep 1.5s
Show
Sleep 10s

# Scene 2: 승인 → 재개
Hide
Type "bash ../mocks/demo-plan-resume.sh"
Enter
Sleep 1.5s
Show
Sleep 11s

# Scene 3: 간단 모드
Hide
Type "bash ../mocks/demo-simple-mode.sh"
Enter
Sleep 1.5s
Show
Sleep 8s
Sleep 1.5s
