#!/bin/bash
set -u

DIR="$HOME/Pictures/Screenshots"

mkdir -p "$DIR"

FILENAME="$DIR/areashot-$(date +%Y-%m-%d_%H-%M-%S).png"

GEOM="$(slurp)" || {
  notify-send "Screenshot Cancelled" "No region selected"
  exit 1
}

if [ -z "$GEOM" ]; then
  notify-send "Screenshot Cancelled" "No region selected"
  exit 1
fi

if grim -g "$GEOM" "$FILENAME"; then
  notify-send "Screenshot Saved" "$FILENAME"
else
  notify-send "Screenshot Failed" "grim could not capture the region"
  exit 1
fi
