#!/bin/bash
set -u

DIR="$HOME/Pictures/Screenshots"

mkdir -p "$DIR"

FILENAME="$DIR/fullshot-$(date +%Y-%m-%d_%H-%M-%S).png"

if grim "$FILENAME"; then
  notify-send "Screenshot Saved" "$FILENAME"
else
  notify-send "Screenshot Failed" "grim could not capture the screen"
  exit 1
fi
