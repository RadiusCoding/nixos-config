#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/wallpapers"
POLYBAR_COLORS="$HOME/.cache/wal/polybar_colors.ini"

# Bootstrap: ensure polybar_colors.ini exists with defaults before first wal run
ensure_defaults() {
    mkdir -p "$HOME/.cache/wal"
    if [ ! -f "$POLYBAR_COLORS" ]; then
        cat > "$POLYBAR_COLORS" <<'EOF'
[colors]
background = #1a1a2e
foreground = #ffffff
accent = #e94560
EOF
    fi
}

ensure_defaults

# Pick a random wallpaper
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \) | shuf -n 1)

if [ -z "$WALLPAPER" ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Set wallpaper with feh
feh --bg-fill "$WALLPAPER"

# Extract colors with pywal (suppress terminal sequences)
wal -i "$WALLPAPER" -n -q

# Source the generated colors
source "$HOME/.cache/wal/colors.sh"

# Calculate luminance of background to pick readable foreground
hex_to_luminance() {
    hex="${1#\#}"
    r=$(printf '%d' "0x${hex:0:2}")
    g=$(printf '%d' "0x${hex:2:2}")
    b=$(printf '%d' "0x${hex:4:2}")
    # Relative luminance (perceived brightness)
    echo "scale=4; (0.299 * $r + 0.587 * $g + 0.114 * $b) / 255" | bc
}

bg="${color0}"
lum=$(hex_to_luminance "$bg")

# Pick white or black text based on background brightness
if (( $(echo "$lum > 0.5" | bc -l) )); then
    fg="#000000"
else
    fg="#ffffff"
fi

# Write polybar colors file
cat > "$POLYBAR_COLORS" <<EOF
[colors]
background = ${color0}
foreground = ${fg}
accent = ${color4}
EOF

# Restart polybar
"$HOME/.config/polybar/launch.sh" &

# Reload i3 to apply border colors from updated X resources
i3-msg reload &
