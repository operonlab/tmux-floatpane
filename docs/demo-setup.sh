#!/bin/bash
# demo-setup.sh — self-contained stage for docs/demo.tape. Builds everything the
# recording needs and starts an ISOLATED tmux server (socket: fp-demo, own
# config) — your real tmux server and config are never touched.
# Anonymous by construction: a staged full-screen service-log backdrop, an
# identity-free prompt, no hostname in the status line, and a pre-created scratch
# session so the float attaches to a clean shell (magenta rounded border).
set -u
SOCK=fp-demo
WORK=/tmp/vhs-floatpane-demo
APP=/tmp/demo-app
PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMUX_BIN="${TMUX_BIN:-tmux}"

mkdir -p "$WORK"

# ── clean, anonymous shell for every pane ──
cat > "$WORK/rc.sh" <<'RC'
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export LANG=en_US.UTF-8
PS1='\[\e[38;2;166;227;161m\] dev \[\e[38;2;137;180;250m\]\W\[\e[0m\] ❯ '
PROMPT_COMMAND=
RC

# ── full-screen backdrop: a fake Flask dev-server log (static, no real data) ──
cat > "$WORK/scene.sh" <<'SCENE'
export PATH="/opt/homebrew/bin:/usr/bin:/bin"
clear
printf ' \033[38;2;166;227;161m*\033[0m Serving Flask app '\''demo-app'\'' (lazy loading)\n'
printf ' \033[38;2;166;227;161m*\033[0m Environment: development\n'
printf ' \033[38;2;249;226;175m*\033[0m Debug mode: on\n'
printf ' \033[38;2;166;227;161m*\033[0m Running on http://127.0.0.1:5000 (Press CTRL+C to quit)\n'
printf ' \033[38;2;166;227;161m*\033[0m Restarting with stat\n\n'
for line in \
  '127.0.0.1 - - [14/Jul] "GET /            HTTP/1.1" 200 -' \
  '127.0.0.1 - - [14/Jul] "GET /api/items   HTTP/1.1" 200 -' \
  '127.0.0.1 - - [14/Jul] "GET /static/app.css HTTP/1.1" 304 -' \
  '127.0.0.1 - - [14/Jul] "POST /api/items  HTTP/1.1" 201 -' \
  '127.0.0.1 - - [14/Jul] "GET /api/items/7 HTTP/1.1" 200 -'; do
  printf '\033[2m%s\033[0m\n' "$line"; sleep 0.25
done
SCENE

# ── staged sample project (so the prompt sits in a real project dir) ──
rm -rf "$APP"; mkdir -p "$APP/src"
printf '# demo-app\n\nA tiny sample project.\n' > "$APP/README.md"
printf 'flask\npytest\n' > "$APP/requirements.txt"
printf '"""demo-app."""\n' > "$APP/src/app.py"
git -C "$APP" init -q -b main
git -C "$APP" -c user.name=dev -c user.email=dev@example.com add -A
git -C "$APP" -c user.name=dev -c user.email=dev@example.com commit -qm "initial commit"
# start the scratch note fresh so the float shows exactly what we type
rm -f "$APP/notes.txt"

# ── cockpit-style theme (catppuccin mocha, hardcoded, portable) ──
cat > "$WORK/theme.conf" <<'CONF'
set -g default-terminal "tmux-256color"
set -as terminal-overrides ",xterm-256color:Tc"
set -g mouse on
setw -g mode-keys vi
setw -g automatic-rename off
set -g escape-time 0
set -g status 2
set -g status-interval 2
set -g status-style "bg=#1E1E1E,fg=#cdd6f4"
set -g status-left '#[fg=#a6e3a1,bg=#1E1E1E]#[fg=#11111b,bg=#a6e3a1]  #[fg=#cdd6f4,bg=#313244] #S #[fg=#313244,bg=#1E1E1E] '
set -g status-left-length 30
set -g status-right '#[fg=#f5c2e7,bg=#1E1E1E]#[fg=#11111b,bg=#f5c2e7]  #[fg=#cdd6f4,bg=#313244] #W #[fg=#89dceb,bg=#313244]#[fg=#11111b,bg=#89dceb]  #[fg=#cdd6f4,bg=#313244] %H:%M #[fg=#313244,bg=#1E1E1E]'
set -g status-right-length 120
set -g 'status-format[1]' '#[align=left]#(cat /tmp/vhs-demo-row2-left 2>/dev/null)#[align=right]#(cat /tmp/vhs-demo-row2-right 2>/dev/null)'
set -g window-status-format '#[fg=#6c7086] #I:#W '
set -g window-status-current-format '#[fg=#89b4fa,bold] #I:#W '
set -g window-status-separator ''
set -g message-style 'bg=#f9e2af,fg=#11111b,bold'
CONF

# ── ambient row-2 pills (static demo values, honest set dressing) ──
pill() { printf '#[fg=%s,bg=#1E1E1E]\xee\x82\xb6#[fg=#11111b,bg=%s]%s #[fg=#cdd6f4,bg=#313244] %s #[fg=#313244,bg=#1E1E1E]\xee\x82\xb4 ' "$1" "$1" "$2" "$3"; }
{ pill '#f5c2e7' '' 'AI 5H 40%'; pill '#89b4fa' '' 'CX 5H 65%'; } > /tmp/vhs-demo-row2-left
{ pill '#a6e3a1' '' 'CPU 34%'; pill '#f9e2af' '' 'MEM 16.7/24G'; pill '#94e2d5' '' '↓17K ↑30K'; } > /tmp/vhs-demo-row2-right

# ── isolated server: main working session + a pre-created scratch session ──
"$TMUX_BIN" -L "$SOCK" kill-server 2>/dev/null
sleep 0.3
"$TMUX_BIN" -L "$SOCK" -f "$WORK/theme.conf" new-session -d -s demo -x 118 -y 30 -n main -c "$APP" "bash --rcfile $WORK/rc.sh -i"
"$TMUX_BIN" -L "$SOCK" set -g default-command "bash --rcfile $WORK/rc.sh -i"

# ── floatpane options: compact magenta rounded float, no path-follow noise ──
"$TMUX_BIN" -L "$SOCK" set -g @floatpane-session scratch
"$TMUX_BIN" -L "$SOCK" set -g @floatpane-border-color magenta
"$TMUX_BIN" -L "$SOCK" set -g @floatpane-width 62%
"$TMUX_BIN" -L "$SOCK" set -g @floatpane-height 42%
"$TMUX_BIN" -L "$SOCK" set -g @floatpane-change-path off

# ── pre-create the scratch session (default-command is set, so its shell is the
#    clean anonymous rc) — the toggle then just attaches to it ──
"$TMUX_BIN" -L "$SOCK" new-session -d -s scratch -c "$APP"

# ── load the plugin (binds prefix+t toggle, prefix+P menu) ──
"$TMUX_BIN" -L "$SOCK" run-shell "$PLUGIN/floatpane.tmux"

# ── paint the full-screen backdrop in the main session ──
"$TMUX_BIN" -L "$SOCK" send-keys -t demo:main "bash $WORK/scene.sh" Enter
