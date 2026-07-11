#!/usr/bin/env bash
# floatpane — a floating scratch pane for tmux (hardened fork of omerxx/tmux-floax)
# Upstream: https://github.com/omerxx/tmux-floax (GPL-3.0)
#
# Fixes / hardening over upstream (see README "How this differs from floax"):
#   1. Single-file subcommand dispatch with an fp_ prefix — removes the
#      recursive-recursion bug where upstream embed.sh redefined pop() and
#      shadowed utils.sh's function (bash flat namespace, late binding).
#   2. Safe path-follow — only send-keys `cd` when the scratch foreground is a
#      shell; a TUI in the foreground (vim/bat/fzf...) is left untouched.
#   3. Percentage-step zoom (±5%) so the popup keeps terminal-resize adaptivity
#      (upstream zoom baked absolute cell counts and lost adaptivity until reset).
#   4. State lives in tmux custom options (@fp-*), never `setenv -g`, so the
#      environment namespace stays clean and runtime size resets on server restart.
#   5. Honest popup title — no advertising of the C-M-* hotkeys, which are dead
#      keys under terminals without option-as-meta.
#
# Usage: floatpane.sh {toggle|menu|zoom in|out|full|reset|embed|popout|lock|unlock}

set -u

# Self-locate so hotkey re-binds point at this exact file (no hardcoded paths).
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$CURRENT_DIR/floatpane.sh"

# ── option reader ─────────────────────────────────────────────
# $1=option name  $2=default. @floatpane-* are user settings; @fp-* are runtime state.
fp_opt() {
    local v
    v="$(tmux show-option -gqv "$1")"
    printf '%s\n' "${v:-$2}"
}

FP_SESSION="$(fp_opt @floatpane-session scratch)"
FP_DEF_W="$(fp_opt @floatpane-width 80%)"
FP_DEF_H="$(fp_opt @floatpane-height 70%)"
FP_BORDER="$(fp_opt @floatpane-border-color magenta)"
# text-color default MUST be `default`: upstream floax defaulted to blue, which
# tints every `default`-fg glyph inside the popup ANSI blue (echo/lazygit/...).
FP_TEXT="$(fp_opt @floatpane-text-color default)"
FP_FOLLOW="$(fp_opt @floatpane-change-path on)"
FP_HOTKEYS="$(fp_opt @floatpane-hotkeys on)"
FP_TITLE_DEFAULT=" float │ menu → -/+ size · f full · r reset "

# ── session lifecycle ─────────────────────────────────────────
fp_ensure_session() {
    if ! tmux has-session -t "$FP_SESSION" 2>/dev/null; then
        tmux new-session -d -s "$FP_SESSION" -c "${1:-$HOME}"
    fi
    # A global `detach-on-destroy off` (a common sesh convention) must be
    # overridden to `on` for scratch, else exiting the popup shell jumps to a
    # different session (the main session nesting itself inside the popup).
    tmux set -t "$FP_SESSION" status off >/dev/null 2>&1
    tmux set -t "$FP_SESSION" detach-on-destroy on >/dev/null 2>&1
}

# ── safe path-follow ──────────────────────────────────────────
fp_follow_path() {
    [ "$FP_FOLLOW" = "on" ] || return 0
    local want have fg
    want="$1"
    have="$(tmux display -t "$FP_SESSION" -p '#{pane_current_path}')"
    [ "$want" = "$have" ] && return 0
    fg="$(tmux display -t "$FP_SESSION" -p '#{pane_current_command}')"
    case "$fg" in
        zsh|bash|sh|fish|nu) tmux send-keys -t "$FP_SESSION" -R " cd \"$want\"" C-m ;;
        *) ;;  # TUI in foreground: skip, do not inject keystrokes into it
    esac
}

# ── popup open (detach-reopen is the only live-resize handle) ──
fp_popup_open() {
    local w h title
    w="$(fp_opt @fp-cur-width "$FP_DEF_W")"
    h="$(fp_opt @fp-cur-height "$FP_DEF_H")"
    # Title precedence: runtime override (lock hint) → user setting → default.
    title="$(fp_opt @fp-title-override "$(fp_opt @floatpane-title "$FP_TITLE_DEFAULT")")"
    tmux popup \
        -S "fg=$FP_BORDER" -s "fg=$FP_TEXT" \
        -T "$title" -w "$w" -h "$h" -b rounded -E \
        "tmux attach-session -t \"$FP_SESSION\""
}

# ── popup-time root-table hotkeys (opt-in via @floatpane-hotkeys) ──
# ponytail: bind -n is server-global; multiple meta-capable clients on one server
# can collide. Off by leaving @floatpane-hotkeys=off; upgrade path = client-scoped
# key table if you ever attach a second meta-capable client.
fp_bind_hotkeys() {
    [ "$FP_HOTKEYS" = "on" ] || return 0
    tmux bind -n C-M-s run "bash '$SELF' zoom in"
    tmux bind -n C-M-b run "bash '$SELF' zoom out"
    tmux bind -n C-M-f run "bash '$SELF' zoom full"
    tmux bind -n C-M-r run "bash '$SELF' zoom reset"
    tmux bind -n C-M-e run "bash '$SELF' embed"
    tmux bind -n C-M-d run "bash '$SELF' lock"
}

fp_unbind_hotkeys() {
    local k
    for k in C-M-s C-M-b C-M-f C-M-r C-M-e C-M-d C-M-u; do
        tmux unbind -n "$k" 2>/dev/null
    done
}

fp_set_title_and_reopen() {  # $1=override title; empty string = clear back to user/default
    if [ -n "$1" ]; then
        tmux set -g @fp-title-override "$1"
    else
        tmux set -gu @fp-title-override 2>/dev/null
    fi
    tmux detach-client
    fp_popup_open
}

# ── core: toggle ──────────────────────────────────────────────
fp_toggle() {
    local cur
    cur="$(tmux display -p '#{session_name}')"
    if [ "$cur" = "$FP_SESSION" ]; then
        fp_unbind_hotkeys
        tmux detach-client
    else
        local here
        here="$(tmux display -p '#{pane_current_path}')"
        tmux set -g @fp-origin "$cur"
        fp_ensure_session "$here"
        fp_follow_path "$here"
        fp_bind_hotkeys
        if ! fp_popup_open; then
            # Stale runtime size: reset and retry (upstream fallback design).
            tmux set -gu @fp-cur-width 2>/dev/null
            tmux set -gu @fp-cur-height 2>/dev/null
            fp_popup_open
        fi
    fi
}

# ── zoom: percentage step, keeps adaptivity ───────────────────
fp_pct() {  # $1=cur (e.g. 80%)  $2=delta → clamp 20..100 → "85%"
    local n
    n="${1%\%}"
    case "$n" in (*[!0-9]*) n="${2#-}0" ;; esac  # non-numeric stale value: fall back to step base
    n=$((n + $2))
    [ "$n" -lt 20 ] && n=20
    [ "$n" -gt 100 ] && n=100
    printf '%s%%\n' "$n"
}

fp_zoom() {
    local w h
    w="$(fp_opt @fp-cur-width "$FP_DEF_W")"
    h="$(fp_opt @fp-cur-height "$FP_DEF_H")"
    case "$1" in
        in)    w="$(fp_pct "$w" -5)"; h="$(fp_pct "$h" -5)" ;;
        out)   w="$(fp_pct "$w"  5)"; h="$(fp_pct "$h"  5)" ;;
        full)  w="100%"; h="100%" ;;
        reset) w="$FP_DEF_W"; h="$FP_DEF_H" ;;
        *) exit 1 ;;
    esac
    tmux set -g @fp-cur-width "$w"
    tmux set -g @fp-cur-height "$h"
    tmux detach-client
    fp_popup_open
}

# ── embed / popout ────────────────────────────────────────────
fp_embed() {  # inside scratch: land the current window back onto the origin session
    local origin nwin
    origin="$(fp_opt @fp-origin "")"
    [ -z "$origin" ] && exit 0
    fp_unbind_hotkeys
    nwin="$(tmux list-windows -t "$FP_SESSION" 2>/dev/null | wc -l | tr -d ' ')"
    # Add a spare window before moving the last one out, else the session dies
    # and the next toggle fails.
    [ "$nwin" -eq 1 ] && tmux neww -d -t "$FP_SESSION"
    # -s pins scratch's current window explicitly: with no client context
    # (headless/tests) a bare movew resolves to the wrong session's window.
    # A trailing colon target = next free index in that session.
    tmux movew -s "${FP_SESSION}:" -t "${origin}:"
    tmux detach-client 2>/dev/null
}

fp_popout() {  # outside scratch: pop the current window out into the float
    local cur
    cur="$(tmux display -p '#{session_name}')"
    [ "$cur" = "$FP_SESSION" ] && exit 0
    tmux set -g @fp-origin "$cur"
    fp_ensure_session "$(tmux display -p '#{pane_current_path}')"
    tmux movew -s "${cur}:" -t "${FP_SESSION}:"
    fp_popup_open
}

# ── lock / unlock (let a popup TUI eat the C-M-* keys back) ────
fp_lock() {
    [ "$FP_HOTKEYS" = "on" ] || return 0
    fp_unbind_hotkeys
    tmux bind -n C-M-u run "bash '$SELF' unlock"
    fp_set_title_and_reopen " float │ hotkeys locked · C-M-u unlock "
}

fp_unlock() {
    fp_bind_hotkeys
    fp_set_title_and_reopen ""
}

# ── menu (meta-free entry; the only zoom path when hotkeys are off) ──
fp_menu() {
    local cur
    cur="$(tmux display -p '#{session_name}')"
    if [ "$cur" != "$FP_SESSION" ]; then
        tmux menu -T " float " \
            "pop window out"  p "run \"bash '$SELF' popout\""
        return
    fi
    if [ "$FP_HOTKEYS" = "on" ]; then
        tmux menu -T " float " \
            "size down"        - "run \"bash '$SELF' zoom in\"" \
            "size up"          + "run \"bash '$SELF' zoom out\"" \
            "full screen"      f "run \"bash '$SELF' zoom full\"" \
            "reset size"       r "run \"bash '$SELF' zoom reset\"" \
            "" \
            "embed to session" e "run \"bash '$SELF' embed\"" \
            "lock hotkeys"     l "run \"bash '$SELF' lock\""
    else
        tmux menu -T " float " \
            "size down"        - "run \"bash '$SELF' zoom in\"" \
            "size up"          + "run \"bash '$SELF' zoom out\"" \
            "full screen"      f "run \"bash '$SELF' zoom full\"" \
            "reset size"       r "run \"bash '$SELF' zoom reset\"" \
            "" \
            "embed to session" e "run \"bash '$SELF' embed\""
    fi
}

# ── dispatch (skipped when sourced, so tests can call fp_* directly) ──
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    case "${1:-toggle}" in
        toggle) fp_toggle ;;
        menu)   fp_menu ;;
        zoom)   fp_zoom "${2:-reset}" ;;
        embed)  fp_embed ;;
        popout) fp_popout ;;
        lock)   fp_lock ;;
        unlock) fp_unlock ;;
        *) echo "usage: floatpane.sh {toggle|menu|zoom in|out|full|reset|embed|popout|lock|unlock}" >&2; exit 1 ;;
    esac
fi
