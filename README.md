# tmux-floatpane

> 中文說明請見 [docs/zh.md](docs/zh.md)

A **floating scratch terminal for tmux** — press one key and a small terminal
window slides open on top of whatever you're doing. Press the same key again and
it disappears, remembering exactly what you left there.

> **Honest framing:** this is a *hardened fork* of the excellent
> [omerxx/tmux-floax](https://github.com/omerxx/tmux-floax) (GPL-3.0). As of
> 2026-07, floax has ~848 stars and its last commit was 2026-02-24 with ~37 open
> issues — it is **semi-dormant, not dead**, and it still works. This fork exists
> because I hit a handful of specific bugs and wanted them fixed cleanly (see
> [How this differs from floax](#how-this-differs-from-floax)). It is **not** a
> "successor" and makes no claim about floax's future. Star counts and issue
> numbers drift — check [the upstream repo](https://github.com/omerxx/tmux-floax)
> for the current picture.

---

## 1. What is this?

Imagine you're working in your terminal and you need a quick side space — to run
one command, check something, jot a note, poke at a REPL — without disturbing
your current layout.

`tmux-floatpane` gives you that. One key press pops up a **floating window**
in the middle of your screen. It's a real, persistent terminal session (called
`scratch`), so anything you leave running there is still there next time you open
it. One more key press hides it again. That's the whole idea.

You can make it bigger or smaller, throw it fullscreen, or "pop" a normal window
in and out of the float — all from a small menu, no arcane shortcuts required.

---

## 2. Quickstart

You need **tmux 3.3 or newer** (`tmux -V` to check). Pick one of the two paths
below. Both end with the same result: **press `prefix` then `t`** to toggle the
float. (`prefix` is your tmux prefix key — `Ctrl-b` unless you changed it.)

### Path A — I don't use a plugin manager (works right now)

Copy-paste these three steps into your terminal:

```sh
# 1. Download the plugin somewhere permanent
git clone https://github.com/joneshong/tmux-floatpane ~/.tmux/plugins/tmux-floatpane

# 2. Tell tmux to load it — appends one line to your config
echo "run-shell ~/.tmux/plugins/tmux-floatpane/floatpane.tmux" >> ~/.tmux.conf

# 3. Reload tmux config (inside tmux: press prefix then r, or run this)
tmux source-file ~/.tmux.conf
```

Now press `prefix` `t`. Done.

### Path B — I use TPM (the tmux plugin manager)

**If you don't have TPM yet**, install it first (one command):

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

...and make sure the very last line of your `~/.tmux.conf` is:

```tmux
run '~/.tmux/plugins/tpm/tpm'
```

**Then add this plugin.** Put this line in `~/.tmux.conf` *above* the `run` line:

```tmux
set -g @plugin 'joneshong/tmux-floatpane'
```

Reload your config (`prefix` `r`), then press `prefix` `I` (capital i) to have TPM
download it. Now `prefix` `t` toggles the float.

### Try the menu

Press `prefix` `P` to open a little menu where you can resize (`-` / `+`), go
fullscreen (`f`), reset the size (`r`), or embed the window back into your normal
session (`e`). No keyboard gymnastics needed.

---

## 3. Demo

*Demo GIF coming soon.*

---

## 4. Options

Set any of these in `~/.tmux.conf` **before** the line that loads the plugin.
Every option has a sensible default, so you can ignore this whole table until you
want to change something.

| Option | Default | What it does (plain words) |
|---|---|---|
| `@floatpane-bind-toggle` | `t` | The key (after your prefix) that shows/hides the float. Note: the default `t` replaces tmux's built-in `prefix` + `t` clock binding. |
| `@floatpane-bind-menu` | `P` | The key (after your prefix) that opens the resize/menu. |
| `@floatpane-root-bind` | _(empty)_ | A **no-prefix** shortcut to toggle, e.g. set to `M-p` (Alt-p). Empty means off. ⚠️ see note below. |
| `@floatpane-hotkeys` | `on` | While the float is open, extra `Ctrl-Alt-*` shortcuts resize it. Set `off` to disable them. ⚠️ see note below. |
| `@floatpane-session` | `scratch` | The name of the hidden terminal session the float uses. |
| `@floatpane-width` | `80%` | How wide the float opens. Accepts `%` or a column count. |
| `@floatpane-height` | `70%` | How tall the float opens. Accepts `%` or a row count. |
| `@floatpane-border-color` | `magenta` | Colour of the float's border. |
| `@floatpane-text-color` | `default` | Text colour inside the float. Leave as `default` unless you have a reason. |
| `@floatpane-title` | _(built-in)_ | Custom title shown on the float's top border. |
| `@floatpane-change-path` | `on` | When you open the float, `cd` it to your current folder (only when a shell is in front — never interrupts a running editor). |

Example:

```tmux
set -g @floatpane-width '90%'
set -g @floatpane-height '80%'
set -g @floatpane-bind-toggle 'j'
set -g @floatpane-root-bind 'M-p'
```

> ### ⚠️ A note on the two global-shortcut options
>
> `@floatpane-root-bind` and the `@floatpane-hotkeys` `Ctrl-Alt-*` keys are
> installed as **server-global** tmux bindings (`bind -n`). That means they apply
> to **every** client attached to the same tmux server. If you attach two
> terminals to one server and both can send those keys, they can collide. This is
> harmless for a single-client setup (the common case) but worth knowing. If it
> ever bites you, set `@floatpane-hotkeys off` and leave `@floatpane-root-bind`
> empty — the `prefix`-based keys and the menu do everything without any global
> bindings.

---

## 5. Uninstall

To fully remove every shortcut and clean up, run this from an attached tmux
client:

```sh
bash ~/.tmux/plugins/tmux-floatpane/scripts/teardown.sh
```

Then delete the plugin line from `~/.tmux.conf` (the `run-shell ...floatpane.tmux`
line, or the `set -g @plugin 'joneshong/tmux-floatpane'` line) and reload with
`prefix` `r`. The teardown leaves your own `@floatpane-*` config lines alone —
remove those by hand if you added any.

The `scratch` session itself — and anything you left running inside it — is
intentionally **not** killed by teardown, so you don't lose work. Remove it
yourself if you want a full clean slate:

```sh
tmux kill-session -t scratch
```

---

## 6. Troubleshooting / FAQ

**Q: I press `prefix t` and nothing happens.**
First, confirm your prefix key (default `Ctrl-b`). Then reload your config
(`prefix` `r`) and check the binding exists:
`tmux list-keys | grep floatpane`. If it's empty, the plugin line isn't being
loaded — make sure it comes *before* the TPM `run` line (Path B) or that the
`run-shell` path is correct (Path A).

**Q: When I close the shell inside the float, it jumps to a weird session.**
That's what this fork specifically fixes — the float forces
`detach-on-destroy on` for its own session. If you still see it, you may have an
older copy loaded; run the teardown above and reload.

**Q: The `Ctrl-Alt-` resize shortcuts do nothing.**
Some terminals (and terminal multiplexers) don't send `Alt`/`Meta` as tmux
expects, so those keys arrive dead. That's expected and known — just use the menu
instead (`prefix` `P` → `-` / `+` / `f`). You can also turn the shortcuts off
entirely with `set -g @floatpane-hotkeys off`.

**Q: The float opens at the wrong size / a stale size.**
Open the menu (`prefix` `P`) and choose **reset size** (`r`). Sizes are stored per
running server and reset to your configured defaults when tmux restarts.

**Q: Can I put a normal window into the float, or take one out?**
Yes. From inside the float, menu → **embed to session** drops the current window
back onto the session you came from. From a normal window, menu → **pop window
out** floats it.

---

## 7. Testing / CI

Not everything can be tested without a human watching a screen. This repo is
honest about the split:

**Verified automatically** (`bash tests/smoke.sh`, and in CI via shellcheck):

- every script parses (`bash -n`)
- an unknown subcommand prints `usage:` and exits `1` (no crash)
- `@floatpane-*` option reads return the right defaults and honour overrides
- `@floatpane-hotkeys on|off` correctly gates the `Ctrl-Alt-*` bindings
- `floatpane.tmux` installs the prefix bindings
- `teardown.sh` removes every binding it installed

All of the above run against a throwaway, isolated tmux socket — your real tmux
server is never touched.

**Must be checked by a human** (a tmux popup needs an attached client, which a
headless CI runner does not have): that the popup actually **renders**, resizes,
goes fullscreen, embeds/pops out, and locks/unlocks visually. The smoke script
prints these as `SKIP`. To check them, install the plugin and press the keys.

---

## How this differs from floax

Named credit to **[Omer Hamerman (omerxx)](https://github.com/omerxx)** for the
original design and implementation — this fork is a rewrite of the same idea, not
a from-scratch invention.

| # | Area | Upstream floax behaviour | This fork |
|---|---|---|---|
| 1 | **Recursion bug** | `embed.sh` redefined `pop()`, shadowing `utils.sh`'s function in bash's flat namespace → a non-terminating recursion path. | Single-file `fp_`-prefixed subcommand dispatch — the name collision can't happen. |
| 2 | **Path follow** | `cd`'d the float to your current path unconditionally; a running editor/TUI could receive stray keystrokes (wishlisted in upstream #72). | Only sends `cd` when a plain shell is in the foreground; a TUI is left untouched. |
| 3 | **Zoom** | Resizing baked absolute cell counts, so the float stopped adapting to terminal resize until reset. | Zoom steps in **percentages** (±5%), so it keeps adapting. |
| 4 | **State** | Stored via `setenv -g`, polluting the environment namespace. | Stored in tmux custom options (`@fp-*`); clean namespace, auto-resets on server restart. |
| 5 | **Honest hotkey docs** | Advertised `Ctrl-Alt-*` shortcuts that are dead keys in terminals without option-as-meta. | Popup title never advertises those keys; they're opt-in (`@floatpane-hotkeys`) and the menu is the always-works path. |

### Migrating from floax

1. Remove your floax plugin line (`set -g @plugin 'omerxx/tmux-floax'`) and add
   `set -g @plugin 'joneshong/tmux-floatpane'` (or the `run-shell` line).
2. Rename your options: every `@floax-*` becomes `@floatpane-*` (e.g.
   `@floax-width` → `@floatpane-width`, `@floax-bind` → `@floatpane-bind-toggle`).
3. Reload (`prefix` `r`); `prefix` `t` toggles as before.

---

## Credits / License

- **Original idea & implementation:** [omerxx/tmux-floax](https://github.com/omerxx/tmux-floax)
  by Omer Hamerman, licensed GPL-3.0.
- **This hardened fork:** maintained by [joneshong](https://github.com/joneshong).

Because it derives from a GPL-3.0 work, `tmux-floatpane` is released under the
**GNU General Public License v3.0** — see [LICENSE](LICENSE) for the full text.

繁體中文快速上手與 FAQ 見 [docs/zh.md](docs/zh.md)。
