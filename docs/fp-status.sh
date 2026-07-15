#!/usr/bin/env bash
# fp-status.sh — demo-only cockpit reader. Prints tmux-floatpane's REAL live
# state for the Row-2 status capsule (session name / float geometry / show
# state). tmux calls this from a #() in docs/demo-setup.sh's status-format on
# the ISOLATED fp-demo server, so $TMUX already points at that server — the bare
# `tmux` calls below target it (same convention floatpane.sh itself uses). This
# is NOT part of the setup/vhs pipeline, so it never risks a live server.
#
# Usage: fp-status.sh {session|size|state}
set -u

opt() { tmux show-option -gqv "$1" 2>/dev/null; }

sess="$(opt @floatpane-session)"; sess="${sess:-scratch}"

case "${1:-}" in
	session)
		printf '%s' "$sess"
		;;
	size)
		w="$(opt @fp-cur-width)";  w="${w:-$(opt @floatpane-width)}";  w="${w:-80%}"
		h="$(opt @fp-cur-height)"; h="${h:-$(opt @floatpane-height)}"; h="${h:-70%}"
		printf '%s×%s' "$w" "$h"
		;;
	state)
		if tmux has-session -t "$sess" 2>/dev/null; then
			if tmux list-clients -t "$sess" 2>/dev/null | grep -q .; then
				printf 'shown'
			else
				printf 'ready'
			fi
		else
			printf 'off'
		fi
		;;
	*)
		:
		;;
esac
