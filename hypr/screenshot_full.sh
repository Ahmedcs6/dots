
#!/bin/bash

DIR="$HOME/Pictures/Screenshots"

mkdir -p "$DIR"

FILENAME="$DIR/fullshot-$(date +%Y-%m-%d_%H-%M-%S).png"

grim "$FILENAME"

notify-send "Screenshot Saved" "$FILENAME"