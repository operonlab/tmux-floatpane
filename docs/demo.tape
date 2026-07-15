# tmux-floatpane demo — one key pops up a floating scratch terminal on top of
# your work (rounded magenta border); press again to hide it; it remembers
# whatever you left inside.
#
# TIMELINE NOTE: each prefix+t beat holds the PREVIOUS screen static while the
# KeyCastr bezel (⌃B then ⌃B T) is composited on top, and only THEN presses the
# key so the float toggles AFTER the bezel finishes — "show the keys, then act".
# floatpane toggles INSTANTLY on the keypress, so the gap between Ctrl+B and
# Type "t" is WIDE (both ⌃B and ⌃B T must be readable before the toggle fires).
# The overlay windows in docs/demo-overlay.sh land inside these static holds.
#
# Fully self-contained: docs/demo-setup.sh stages a full-screen service-log
# backdrop, a cockpit-style themed ISOLATED tmux server (socket fp-demo) and a
# pre-created clean scratch session. Re-record from the repo root with:
#   vhs docs/demo.tape && bash docs/demo-overlay.sh
Output "docs/demo-raw.gif"
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

# --- beat 1: bezel over the cockpit, THEN one key pops the float open ---
Sleep 1500ms
Ctrl+B
Sleep 1000ms
Type "t"
Sleep 2000ms

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

# --- beat 2: bezel over the float, THEN the same key hides it ---
Sleep 1500ms
Ctrl+B
Sleep 1000ms
Type "t"
Sleep 2000ms

# --- beat 3: bezel over your untouched layout, THEN it comes back as you left it ---
Sleep 1500ms
Ctrl+B
Sleep 1000ms
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
