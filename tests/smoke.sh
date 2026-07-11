#!/usr/bin/env bash
# smoke.sh — headless smoke tests for tmux-floatpane.
#
# What CAN be verified headless (this script):
#   - every script parses (bash -n)
#   - unknown subcommand prints usage and exits 1 (no crash)
#   - fp_opt reads option defaults + user overrides on an isolated socket
#   - @floatpane-hotkeys on|off gates the C-M-* root bindings
#   - floatpane.tmux installs the prefix bindings
#   - teardown.sh removes every binding it installed
#
# What CANNOT be verified headless (needs an attached client — human check):
#   - the popup actually renders, resizes, embeds/pops out, and locks visually.
#   These are printed as SKIP; see README "Testing / CI".
#
# All tmux calls run against a throwaway `-L` socket via a PATH shim, so the
# user's real (default-socket) server is never touched.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOCK="floatpane-smoke-$$"
REALTMUX="$(command -v tmux || true)"
SHIM=""
pass=0
fail=0

ok()  { pass=$((pass + 1)); printf 'PASS: %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1"; }
skip() { printf 'SKIP: %s\n' "$1"; }

cleanup() {
    [ -n "$REALTMUX" ] && "$REALTMUX" -L "$SOCK" kill-server 2>/dev/null
    # macOS can leave the socket file behind after kill-server; sweep it.
    rm -f "${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)/$SOCK" 2>/dev/null
    [ -n "$SHIM" ] && rm -rf "$SHIM"
}
trap cleanup EXIT

# ── 1. syntax (always runnable) ───────────────────────────────
for f in "$ROOT/floatpane.tmux" "$ROOT/scripts/floatpane.sh" "$ROOT/scripts/teardown.sh"; do
    if bash -n "$f" 2>/dev/null; then ok "bash -n $(basename "$f")"; else bad "bash -n $(basename "$f")"; fi
done

if [ -z "$REALTMUX" ]; then
    skip "tmux not installed — server-backed checks skipped"
    printf -- '----\n%d passed, %d failed\n' "$pass" "$fail"
    [ "$fail" -eq 0 ] && exit 0 || exit 1
fi

# ── PATH shim: any bare `tmux` routes to the isolated socket ───
SHIM="$(mktemp -d)"
cat > "$SHIM/tmux" <<EOF
#!/usr/bin/env bash
exec "$REALTMUX" -L "$SOCK" "\$@"
EOF
chmod +x "$SHIM/tmux"
"$REALTMUX" -L "$SOCK" -f /dev/null new-session -d -s probe

# ── 2. unknown subcommand → usage + exit 1 ────────────────────
out="$(FP_ROOT="$ROOT" PATH="$SHIM:$PATH" bash "$ROOT/scripts/floatpane.sh" bogus 2>&1)"
rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q '^usage:'; then
    ok "unknown subcommand → usage + exit 1"
else
    bad "unknown subcommand (rc=$rc out=[$out])"
fi

# ── 3. fp_opt: default then user override ─────────────────────
v_def="$(FP_ROOT="$ROOT" PATH="$SHIM:$PATH" bash -c 'source "$FP_ROOT/scripts/floatpane.sh"; fp_opt @floatpane-width 80%')"
"$REALTMUX" -L "$SOCK" set -g @floatpane-width 55%
v_ovr="$(FP_ROOT="$ROOT" PATH="$SHIM:$PATH" bash -c 'source "$FP_ROOT/scripts/floatpane.sh"; fp_opt @floatpane-width 80%')"
"$REALTMUX" -L "$SOCK" set -gu @floatpane-width
if [ "$v_def" = "80%" ] && [ "$v_ovr" = "55%" ]; then
    ok "fp_opt default=80% override=55%"
else
    bad "fp_opt default=[$v_def] override=[$v_ovr]"
fi

# ── 4. @floatpane-hotkeys gate ────────────────────────────────
FP_ROOT="$ROOT" PATH="$SHIM:$PATH" bash -c 'tmux set -g @floatpane-hotkeys off; source "$FP_ROOT/scripts/floatpane.sh"; fp_bind_hotkeys'
off_hit="$("$REALTMUX" -L "$SOCK" list-keys -T root 2>/dev/null | grep -c 'C-M-s' || true)"
FP_ROOT="$ROOT" PATH="$SHIM:$PATH" bash -c 'tmux set -g @floatpane-hotkeys on; source "$FP_ROOT/scripts/floatpane.sh"; fp_bind_hotkeys'
on_hit="$("$REALTMUX" -L "$SOCK" list-keys -T root 2>/dev/null | grep -c 'C-M-s' || true)"
if [ "$off_hit" -eq 0 ] && [ "$on_hit" -ge 1 ]; then
    ok "@floatpane-hotkeys off→unbound on→bound"
else
    bad "@floatpane-hotkeys gate (off=$off_hit on=$on_hit)"
fi

# ── 5. floatpane.tmux installs prefix bindings ────────────────
FP_ROOT="$ROOT" PATH="$SHIM:$PATH" bash "$ROOT/floatpane.tmux"
keys="$("$REALTMUX" -L "$SOCK" list-keys 2>/dev/null)"
if printf '%s' "$keys" | grep -q "floatpane.sh' toggle" && printf '%s' "$keys" | grep -q "floatpane.sh' menu"; then
    ok "floatpane.tmux installed toggle + menu bindings"
else
    bad "floatpane.tmux bindings missing"
fi

# ── 6. teardown removes everything it installed ───────────────
FP_ROOT="$ROOT" PATH="$SHIM:$PATH" bash "$ROOT/scripts/teardown.sh" >/dev/null 2>&1
keys_after="$("$REALTMUX" -L "$SOCK" list-keys 2>/dev/null)"
if printf '%s' "$keys_after" | grep -q 'floatpane.sh'; then
    bad "teardown left floatpane bindings behind"
else
    ok "teardown removed all floatpane bindings"
fi

# ── popup-visual checks: cannot run without an attached client ─
skip "popup renders/resizes/embeds/locks — needs attached client (human check)"

printf -- '----\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ] && exit 0 || exit 1
