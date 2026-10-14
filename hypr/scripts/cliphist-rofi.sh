#!/usr/bin/env bash
# Clipboard history picker (cliphist + rofi).
# Enter: copy entry back to the Wayland clipboard.
# Alt+X: delete the selected entry from history.
set -u

PICKED="$(cliphist list | rofi -dmenu -i -p "Clipboard" -kb-custom-1 "Alt+x")"
STATUS=$?

[ -z "${PICKED:-}" ] && exit 0

if [ "$STATUS" -eq 10 ]; then
	printf '%s' "$PICKED" | cliphist delete
	notify-send "Clipboard" "Entry deleted"
elif [ "$STATUS" -eq 0 ]; then
	printf '%s' "$PICKED" | cliphist decode | wl-copy
fi
