#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/.config/hypr/bg"

mapfile -d '' WALLPAPERS < <(
	find "$WALLPAPER_DIR" -type f \
		\( -iname '*.jpg' -o -iname '*.jpeg' \
		-o -iname '*.png' -o -iname '*.webp' \) \
		-print0
)

((${#WALLPAPERS[@]})) || exit 1

WALLPAPER=$(printf '%s\n' "${WALLPAPERS[@]}" | shuf -n 1)

# Generate pywal colors
wal -i "$WALLPAPER" -n || exit 1

# Apply wallpaper
awww img "$WALLPAPER" \
	--transition-type grow \
	--transition-duration 1 \
	--transition-fps 60
