#!/usr/bin/env bash

SERVICE="gamemode"

if [ "$1" = "toggle" ]; then
  if systemctl --user is-active --quiet "$SERVICE"; then
    systemctl --user stop "$SERVICE"
    notify-send "󰊗 Gamemode" "off" >/dev/null 2>&1
  else
    systemctl --user start "$SERVICE"
    notify-send "󰊗 Gamemode" "on" >/dev/null 2>&1
  fi
  exit 0
fi

if ! systemctl --user is-active --quiet "$SERVICE"; then
  echo "{\"text\": \"inactive\", \"tooltip\": \"gamemoded is inactive\", \"alt\": \"inactive\", \"class\": \"inactive\"}"
  exit 0
fi

echo "{\"text\": \"active\", \"tooltip\": \"gamemoded is running\", \"alt\": \"active\", \"class\": \"active\"}"
exit 0
