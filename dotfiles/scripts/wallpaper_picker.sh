#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/wallpapers"
SELECTION="/tmp/.wallpaper_selection"

rm -f "$SELECTION"

# Collect wallpaper files
shopt -s nullglob
FILES=("$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp,JPG,JPEG,PNG,WEBP})
shopt -u nullglob

[ ${#FILES[@]} -eq 0 ] && exit 0

# Open feh - arrow keys to browse, Enter to select and close
feh --scale-down --auto-zoom --geometry 900x600 --title "wallpaper_picker" \
    --action ";echo %F > $SELECTION && kill \$PPID" \
    "${FILES[@]}"

[ ! -f "$SELECTION" ] && exit 0
SELECTED=$(cat "$SELECTION")
rm -f "$SELECTION"
[ -z "$SELECTED" ] && exit 0

# Set wallpaper
feh --bg-fill "$SELECTED"

# Extract colors with pywal
wal -i "$SELECTED" -n -q

# Source the generated colors
source "$HOME/.cache/wal/colors.sh"

# Calculate luminance for readable foreground
hex_to_luminance() {
    hex="${1#\#}"
    r=$(printf '%d' "0x${hex:0:2}")
    g=$(printf '%d' "0x${hex:2:2}")
    b=$(printf '%d' "0x${hex:4:2}")
    echo "scale=4; (0.299 * $r + 0.587 * $g + 0.114 * $b) / 255" | bc
}

bg="${color0}"
lum=$(hex_to_luminance "$bg")

if (( $(echo "$lum > 0.5" | bc -l) )); then
    fg="#000000"
else
    fg="#ffffff"
fi

# Write polybar colors
cat > "$HOME/.cache/wal/polybar_colors.ini" <<EOF
[colors]
background = ${color0}
foreground = ${fg}
accent = ${color4}
EOF

# Restart polybar (signal existing instance, don't spawn new ones)
polybar-msg cmd restart 2>/dev/null

# Reload i3 to apply border colors
i3-msg reload 2>/dev/null
