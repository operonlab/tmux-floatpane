# tmux-floatpane HERO screenshot — the money shot: a compact floating scratch
# terminal (rounded magenta border, elevated tone) hovering over a real working
# terminal, with a note written and read back inside to prove it's a live,
# persistent shell. Backdrop is the family two-row pill cockpit (catppuccin
# mocha) with a byte-exact Starship-clone prompt; Row-2 right shows the plugin's
# REAL float state via docs/fp-status.sh.
#
# Fully self-contained: docs/demo-setup.sh stages an ISOLATED tmux server
# (socket fp-demo, own config) and a pre-created clean scratch session — your
# real tmux server and config are never touched. Re-shoot from the repo root:
#   vhs docs/screenshot.tape   ->   docs/screenshot.png
Output docs/screenshot.png
Require tmux

Set Shell "bash"
Set FontFamily "MesloLGS Nerd Font Mono"
Set FontSize 20
Set Width 2392
Set Height 640
Set Padding 20
Set TypingSpeed 32ms

# ---- hidden setup: stage the cockpit + attach the working session ----
Hide
Type "bash docs/demo-setup.sh"
Enter
Sleep 3s
Type "clear; tmux -L fp-demo attach -t demo"
Enter
Sleep 1500ms
# taller float so the money shot fills the frame (also reflected live in Row-2 pill)
Type "tmux set -g @floatpane-height 56% >/dev/null; clear"
Enter
Sleep 400ms
Show

# ---- visible: a real working terminal under the two-row pill cockpit ----
Sleep 700ms
Type "# tmux-floatpane: one key pops a floating scratch terminal on top of your work"
Enter
Sleep 400ms
Type "git -c color.ui=always log --stat --oneline"
Enter
Sleep 900ms

# one key: the floating scratch terminal pops open on top of the work
Ctrl+B
Sleep 400ms
Type "t"
Sleep 1300ms

# it's a real shell — leave a note in it, then read it back
Type "# floats on top · keeps whatever you leave here"
Enter
Sleep 250ms
Type `echo "TODO: rotate the staging API token" >> notes.txt`
Enter
Sleep 250ms
Type "cat notes.txt"
Enter
Sleep 1000ms

# freeze on the money shot: the float clearly layered above the working terminal
Screenshot docs/screenshot.png
Sleep 300ms

# ---- hidden teardown: kill the isolated server ----
Hide
Type "tmux -L fp-demo kill-server"
Enter
Sleep 400ms
