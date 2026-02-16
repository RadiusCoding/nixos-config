#!/usr/bin/env bash
source ~/.cache/wal/colors.sh 2>/dev/null
dmenu_run \
    -nb "${color0:-#1a1a2e}" \
    -nf "${foreground:-#ffffff}" \
    -sb "${color4:-#e94560}" \
    -sf "${foreground:-#ffffff}"
