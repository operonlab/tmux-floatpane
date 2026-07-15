#!/bin/bash
# Post-overlay pass: composite KeyCastr-style key bezels onto the raw vhs
# capture at the tape's deterministic timestamps, then re-palette the GIF.
#
#   vhs docs/demo.tape          -> docs/demo-raw.gif
#   bash docs/demo-overlay.sh   -> docs/demo.gif
#
# Bezels come from docs/keycast-bezel.py (PIL render, docs/assets/bezel-*.png).
# The demo presses prefix+t THREE times (open the float / hide it / reopen it) —
# each an INSTANT toggle. Each beat holds the PREVIOUS screen static, shows "⌃B"
# then the chord "⌃B T" ON TOP of it, and the chord window ENDS ~0.15s before the
# float actually toggles — so the bezel is fully read BEFORE the toggle fires
# ("show the keys, then act").
#
# The windows below are EMPIRICALLY tuned to demo-raw.gif's real timeline. The
# typed note between beats 1 and 2 shifts the later beats, so nominal Sleep sums
# do NOT predict them. Measured toggle moments (ffmpeg frame-diff + eyes-on frame
# audit): open ~4.25, hide ~16.00, reopen ~20.40. If you re-time the tape,
# re-measure and re-tune these — do NOT trust the nominal Sleep sums.
set -u
cd "$(dirname "$0")"

[ -f demo-raw.gif ] || { echo "demo-raw.gif missing — run vhs docs/demo.tape first" >&2; exit 1; }
for b in assets/bezel-cb.png assets/bezel-cbt.png; do
  [ -f "$b" ] || { echo "$b missing — run keycast-bezel.py first" >&2; exit 1; }
done

ffmpeg -y -loglevel error -i demo-raw.gif \
  -i assets/bezel-cb.png -i assets/bezel-cbt.png \
  -filter_complex "\
[0:v][1:v]overlay=(W-w)/2:H-h-120:enable='between(t,2.60,3.10)+between(t,14.35,14.85)+between(t,18.75,19.25)'[v1];\
[v1][2:v]overlay=(W-w)/2:H-h-120:enable='between(t,3.10,4.10)+between(t,14.85,15.85)+between(t,19.25,20.25)'[v2];\
[v2]split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5[out]" \
  -map '[out]' demo.gif

echo "demo.gif written ($(du -h demo.gif | cut -f1))"
