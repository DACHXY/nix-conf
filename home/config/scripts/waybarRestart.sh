#!/usr/bin/env bash

#Restart Waybar and swaync
XDG_CONFIG_HOME="$HOME/.dummy" # Prevent swaync use default gtk theme
pkill -f waybar
pkill -f swaync
waybar -c ~/.config/waybar/config.json -s ~/.config/waybar/style.css &
swaync -c ~/.config/swaync/config.json -s ~/.config/swaync/style.css &
