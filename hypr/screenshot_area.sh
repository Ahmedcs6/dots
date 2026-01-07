#!/bin/bash

DIR="$HOME/Pictures/Screenshots"

mkdir -p "$DIR"

FILENAME="$DIR/areashot-$(date +%Y-%m-%d_%H-%M-%S).png"

grim -g "$(slurp)" "$FILENAME"

notify-send "Screenshot Saved" "$FILENAME"
