#!/usr/bin/env bash
# teardown.sh — clean removal. Unbinds every key floatpane installed and clears
# its runtime tmux options. The `scratch` session (and anything left running in
# it) is intentionally preserved — kill it yourself with `tmux kill-session -t
# scratch` if you want it gone too. Your user @floatpane-* settings in
# tmux.conf are left alone (remove those lines yourself).
# Run from an attached client: bash scripts/teardown.sh

set -u

# $1=option name  $2=default
fp_opt() {
    local v
    v="$(tmux show-option -gqv "$1")"
    printf '%s\n' "${v:-$2}"
}

toggle_key="$(fp_opt @floatpane-bind-toggle t)"
menu_key="$(fp_opt @floatpane-bind-menu P)"
root_bind="$(fp_opt @floatpane-root-bind '')"

# prefix-table bindings
[ -n "$toggle_key" ] && tmux unbind "$toggle_key" 2>/dev/null
[ -n "$menu_key" ]   && tmux unbind "$menu_key" 2>/dev/null

# root-table toggle
[ -n "$root_bind" ] && tmux unbind -n "$root_bind" 2>/dev/null

# runtime C-M-* hotkeys (root table)
for k in C-M-s C-M-b C-M-f C-M-r C-M-e C-M-d C-M-u; do
    tmux unbind -n "$k" 2>/dev/null
done

# runtime state options
for o in @fp-cur-width @fp-cur-height @fp-origin @fp-title-override; do
    tmux set -gu "$o" 2>/dev/null
done

printf '%s\n' "floatpane: bindings unbound and runtime options cleared."
