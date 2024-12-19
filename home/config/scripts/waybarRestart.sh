#!/usr/bin/env bash

#Restart Waybar and swaync

killall .waybar-wrapped
killall .swaync-wrapped
waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css &
swaync -s ~/.config/swaync/style.css -c ~/.config/swaync/config.json &
