# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-07-11

First release. A hardened, single-file fork of
[omerxx/tmux-floax](https://github.com/omerxx/tmux-floax) (GPL-3.0).

### Added

- Floating scratch pane via `tmux popup` with a persistent `scratch` session.
- Option-driven key bindings in `floatpane.tmux`:
  - `@floatpane-bind-toggle` (default `t`, prefix table)
  - `@floatpane-bind-menu` (default `P`, prefix table)
  - `@floatpane-root-bind` (default empty = disabled; e.g. `M-p` to enable a
    no-prefix toggle)
- `@floatpane-hotkeys` (`on`|`off`, default `on`) to gate the runtime
  server-global `Ctrl-Alt-*` resize bindings.
- Preserved floax-style options with original defaults: `@floatpane-session`
  (`scratch`), `@floatpane-width` (`80%`), `@floatpane-height` (`70%`),
  `@floatpane-border-color` (`magenta`), `@floatpane-text-color` (`default`),
  `@floatpane-change-path` (`on`), plus optional `@floatpane-title`.
- Menu (`prefix P`) for resize / fullscreen / reset / embed / pop-out / lock —
  works with no meta keys.
- `scripts/teardown.sh` for clean removal (unbinds every binding, clears `@fp-*`
  runtime options).
- `tests/smoke.sh` headless test harness (isolated tmux socket).
- `.github/workflows/ci.yml` running shellcheck and the smoke suite.

### Fixed / hardened over upstream floax

- Root-caused the non-terminating recursion from `embed.sh` redefining `pop()`
  by using single-file `fp_`-prefixed subcommand dispatch.
- Safe path-follow: only injects `cd` when a shell is in the scratch foreground,
  never into a running TUI.
- Percentage-step zoom (±5%) preserves terminal-resize adaptivity.
- State kept in tmux custom options (`@fp-*`) instead of `setenv -g`.
- Popup title no longer advertises the `Ctrl-Alt-*` dead keys.

### Changed (vs. hardcoded origin script)

- Removed all hardcoded absolute paths; scripts self-locate via
  `${BASH_SOURCE[0]}`.
- All key bindings are option-driven rather than fixed.

[0.1.0]: https://github.com/joneshong/tmux-floatpane/releases/tag/v0.1.0
