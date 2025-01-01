#!/usr/bin/env bash

#Restart Waybar and swaync
XDG_CONFIG_HOME="$HOME/.dummy" # Prevent swaync use default gtk theme
killall .waybar-wrapped
killall .swaync-wrapped
waybar -c ~/.config/waybar/config.json -s ~/.config/waybar/style.css &
swaync -c ~/.config/swaync/config.json -s ~/.config/swaync/style.css &
