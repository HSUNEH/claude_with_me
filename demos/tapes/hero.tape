# hero.tape — 3개 시나리오 핵심 장면 조합
Source "common.tape"
Set Height 700
Output "../assets/hero.gif"

# Scene 1: 계획 모드 (계획 수립 → 승인 → /clear → 재개)
Hide
Type "bash ../mocks/demo-plan-mode.sh"
Enter
Sleep 1.5s
Show
Sleep 18s

# Scene 2: 간단 모드
Hide
Type "bash ../mocks/demo-simple-mode.sh"
Enter
Sleep 1.5s
Show
Sleep 8s
Sleep 0.5s
