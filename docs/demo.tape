# tmux-floatpane demo — one key pops up a floating scratch terminal on top of
# your work; press again to hide it; it remembers what you left inside.
#
# Recorded against an isolated tmux server (socket: vhsdemo-floatpane,
# -f /dev/null), never the user's live server.
Output docs/demo.gif
Require tmux

Set Shell "bash"
Set Width 1200
Set Height 660
Set FontSize 15
Set Padding 12
Set TypingSpeed 55ms

# ---- hidden setup ----
Hide
Type "bash /private/tmp/claude-501/-Users-joneshong/aaff1254-ec36-4c2f-98bf-76d62cc8b483/scratchpad/vhs-visual/setup-floatpane.sh"
Enter
Sleep 1s
Type "clear; tmux -L vhsdemo-floatpane attach -t demo"
Enter
Sleep 1500ms
Show

# ---- visible demo ----
Sleep 1500ms

# one key: a floating scratch terminal slides open
Ctrl+B
Sleep 500ms
Type "t"
Sleep 1500ms

# leave something inside it
Type "echo 'this note survives the toggle' > /tmp/floatpane-note.txt"
Enter
Sleep 300ms
Type "cat /tmp/floatpane-note.txt"
Enter
Sleep 2s

# press the same key: the float hides, your layout is untouched
Ctrl+B
Sleep 500ms
Type "t"
Sleep 1800ms

# press again: it comes back exactly as you left it
Ctrl+B
Sleep 500ms
Type "t"
Sleep 2500ms

# ---- hidden teardown ----
Hide
Type "tmux -L vhsdemo-floatpane kill-server"
Enter
Sleep 500ms
Type "rm -f /tmp/floatpane-note.txt"
Enter
Sleep 300ms
