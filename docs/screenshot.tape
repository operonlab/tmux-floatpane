# tmux-floatpane HERO screenshot — a compact floating scratch terminal (rounded
# magenta border, elevated tone) hovering over a full working terminal; a note
# written and read back inside proves it's a real, persistent shell.
# Rendered against an isolated tmux server (socket: shot-floatpane, -f /dev/null)
# — never the user's live server.
Output docs/screenshot.png
Require tmux

Set Shell "bash"
Set FontSize 20
Set Width 1600
Set Height 900
Set Padding 20
Set TypingSpeed 42ms

# ---- hidden setup ----
Hide
Type "bash /private/tmp/claude-501/-Users-joneshong/aaff1254-ec36-4c2f-98bf-76d62cc8b483/scratchpad/hero-shots/tmux-floatpane/setup.sh"
Enter
Sleep 1200ms
Type "clear; tmux -L shot-floatpane attach -t demo"
Enter
Sleep 1500ms
Show

# ---- visible: a normal, full working terminal ----
Sleep 700ms

# one key press: the floating scratch terminal pops open on top
Ctrl+B
Sleep 400ms
Type "t"
Sleep 1300ms

# it's a real shell — leave a note in it, then read it back
Type "clear"
Enter
Sleep 250ms
Type "# floats on top · keeps whatever you leave here"
Enter
Sleep 200ms
Type `echo "TODO: rotate API token" >> notes.txt`
Enter
Sleep 200ms
Type "cat notes.txt"
Enter
Sleep 900ms

# freeze on the money shot: float clearly layered above the working terminal
Screenshot docs/screenshot.png
Sleep 300ms

# ---- hidden teardown ----
Hide
Type "tmux -L shot-floatpane kill-server"
Enter
Sleep 400ms
