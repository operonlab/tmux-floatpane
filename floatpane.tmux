#!/usr/bin/env bash
# floatpane.tmux — TPM entry point. Reads @floatpane-* options and installs the
# key bindings. Loaded once by TPM (or by a manual `run-shell` on plugin path).

set -u

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$CURRENT_DIR/scripts/floatpane.sh"

# $1=option name  $2=default
fp_opt() {
    local v
    v="$(tmux show-option -gqv "$1")"
    printf '%s\n' "${v:-$2}"
}

toggle_key="$(fp_opt @floatpane-bind-toggle t)"
menu_key="$(fp_opt @floatpane-bind-menu P)"
root_bind="$(fp_opt @floatpane-root-bind '')"

# prefix-table bindings (always installed unless the key is set empty)
[ -n "$toggle_key" ] && tmux bind "$toggle_key" run-shell "bash '$SCRIPT' toggle"
[ -n "$menu_key" ]   && tmux bind "$menu_key"   run-shell "bash '$SCRIPT' menu"

# root-table toggle (no prefix). Disabled by default; set e.g. M-p to enable.
[ -n "$root_bind" ] && tmux bind -n "$root_bind" run-shell "bash '$SCRIPT' toggle"

# the guard above is false in the default (empty root_bind) config — don't let
# that leak out as exit 1, or every conf reload prints a scary "returned 1"
exit 0
