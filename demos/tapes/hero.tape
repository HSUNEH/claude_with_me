# hero.tape — 전체 워크플로우 히어로 GIF
# 핵심 기능 3가지를 연속 시연: 계획 강제 → 매뉴얼 추천 → 품질 검사
# Output: demos/assets/hero.gif

Source "common.tape"
Set Height 700

Output "../assets/hero.gif"

# ── Scene 1: 계획 강제 ──
Hide
Type "bash ../mocks/demo-plan-guard.sh"
Enter
Sleep 2s
Show

Sleep 12s
Sleep 2s

# ── Scene 2: 매뉴얼 추천 ──
Hide
Type "bash ../mocks/demo-auto-manual.sh"
Enter
Sleep 2s
Show

Sleep 12s
Sleep 2s

# ── Scene 3: 품질 검사 ──
Hide
Type "bash ../mocks/demo-quality-check.sh"
Enter
Sleep 2s
Show

Sleep 15s

# 마무리
Sleep 3s
