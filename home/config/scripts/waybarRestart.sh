#!/usr/bin/env bash
#Restart Waybar and swaync

killall .waybar-wrapped
killall .swaync-wrapped
waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css &

XDG_CONFIG_HOME="$HOME/.dummy" # Prevent swaync use default gtk theme
swaync -c ~/.config/swaync/config.json -s ~/.config/swaync/style.css &
