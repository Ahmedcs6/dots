#!/usr/bin/env bash
# Toggle wlogout (Catppuccin pill-row): single centered row, 5 buttons.
# Passes css/layout explicitly so no symlinks are needed.
#
# How sizing works: wlogout buttons expand to fill the grid, and the grid
# is the window minus outer margins. Unset margin axes default to ~230px
# (inflates the layer past the screen), so ALL FOUR must be set explicitly.

# Check if wlogout is already running
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

# Detect focused monitor logical size
W=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .width / .scale' | awk -F'.' '{print $1}')
H=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .height / .scale' | awk -F'.' '{print $1}')

# 5 buttons per row (-b 5). Grid sized so the row is centered with breathing
# room on 1366x768 and 1080p alike. Must stay in sync with style.css button
# `margin: 60px 2px` — grid height minus 2x60px is the visible pill height
# (e.g. 768p: grid 300px tall -> 180px pills, room for icon on top + label
# at the bottom without overlap).
GRID_W=$((5 * 180))
GRID_H=300
L=$(((W - GRID_W) / 2))
R=$L
T=$(((H - GRID_H) / 2))
B=$T

wlogout -C "$HOME/.config/wlogout/style.css" -l "$HOME/.config/wlogout/layout" --protocol layer-shell -b 5 -T $T -B $B -L $L -R $R &
