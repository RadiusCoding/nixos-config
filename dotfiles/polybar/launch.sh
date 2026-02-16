#!/usr/bin/env bash

# Terminate already running bar instances
polybar-msg cmd quit 2>/dev/null
killall -q -w polybar 2>/dev/null
sleep 0.5

# Launch polybar on each monitor
if type "xrandr" > /dev/null 2>&1; then
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        MONITOR=$m polybar main &
    done
else
    polybar main &
fi
