# plan-guard.tape — 계획 없이 코딩 시도 → 차단 + 안내 시연
# Output: demos/assets/plan-guard.gif

Source "common.tape"
Set Height 600

Output "../assets/plan-guard.gif"

# bash 명령어 숨기고 실행
Hide
Type "bash ../mocks/demo-plan-guard.sh"
Enter
Sleep 2s
Show

Sleep 12s

# 결과 확인 시간
Sleep 3s
