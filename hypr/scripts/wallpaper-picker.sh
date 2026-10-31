#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/.config/hypr/bg"
mapfile -d '' WALLPAPERS < <(
	find "$WALLPAPER_DIR" -type f \
		\( -iname '*.jpg' -o -iname '*.jpeg' \
		-o -iname '*.png' -o -iname '*.webp' \) \
		-print0 | sort -z
)

((${#WALLPAPERS[@]})) || exit 1

OPTIONS=()

for i in "${!WALLPAPERS[@]}"; do
	file="${WALLPAPERS[$i]}"
	name="$(basename "$file")"
	OPTIONS+=("$file")
	printf '%s\0icon\x1f%s\n' "$name" "$file"
done | rofi -dmenu -i -show-icons -p "Select Wallpaper" >/tmp/wallpaper-selection

SELECTED=$(cat /tmp/wallpaper-selection)
[[ -z "$SELECTED" ]] && exit 0

WALLPAPER=""
for file in "${WALLPAPERS[@]}"; do
	if [[ "$(basename "$file")" == "$SELECTED" ]]; then
		WALLPAPER="$file"
		break
	fi
done

[[ -z "$WALLPAPER" ]] && exit 1

# Generate color palette
wal -i "$WALLPAPER" -n || exit 1

# Apply wallpaper
awww img "$WALLPAPER" \
	--transition-type grow \
	--transition-duration 1 \
	--transition-fps 60
