# tmux-floatpane demo — one key pops up a floating scratch terminal on top of
# your work (rounded magenta border); press again to hide it; it remembers
# whatever you left inside.
# Fully self-contained: docs/demo-setup.sh stages a full-screen service-log
# backdrop, a cockpit-style themed ISOLATED tmux server (socket fp-demo) and a
# pre-created clean scratch session. Re-record from the repo root with:
#   vhs docs/demo.tape
Output "docs/demo.gif"
Require tmux

Set Shell "bash"
Set FontFamily "MesloLGS Nerd Font Mono"
Set FontSize 20
Set Width 1600
Set Height 900
Set Padding 20
Set TypingSpeed 35ms

Hide
Type "bash docs/demo-setup.sh"
Enter
Sleep 3s
Type "clear; tmux -L fp-demo attach -t demo"
Enter
Sleep 1500ms
Show

# the cockpit: a full working terminal running a service in the foreground
Sleep 1800ms

# one key -> a floating scratch terminal slides open on top
Ctrl+B
Sleep 400ms
Type "t"
Sleep 1500ms

# it's a real shell — leave a note in it, then read it back
Type "# floats on top · keeps whatever you leave here"
Enter
Sleep 300ms
Type `echo "TODO: rotate the staging API token" >> notes.txt`
Enter
Sleep 300ms
Type "cat notes.txt"
Enter
Sleep 2500ms

# press the same key -> the float hides, your layout is untouched
Ctrl+B
Sleep 400ms
Type "t"
Sleep 1800ms

# press again -> it comes back exactly as you left it, note and all
Ctrl+B
Sleep 400ms
Type "t"
Sleep 3000ms

Hide
Ctrl+B
Type "t"
Sleep 300ms
Ctrl+B
Type "d"
Sleep 500ms
Type "tmux -L fp-demo kill-server"
Enter
Sleep 500ms
