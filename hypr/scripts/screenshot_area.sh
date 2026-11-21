#!/bin/bash
set -u

DIR="$HOME/Pictures/Screenshots"

mkdir -p "$DIR"

# hyprshot drives its own selection overlay, waits for it to unmap, then
# captures via grim internally — no frame-race between slurp exit and grim,
# which baked slurp's own border into every areashot PNG with the old
# slurp|grim pipeline. Handles clipboard copy + notification itself.
FN="areashot-$(date +%Y-%m-%d_%H-%M-%S).png"

if ! hyprshot -m region -o "$DIR" -f "$FN"; then
  notify-send "Screenshot Cancelled" "No region selected"
  exit 1
fi
