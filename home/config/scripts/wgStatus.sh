#!/usr/bin/env bash

INTERFACE="wg0"

if [ "$1" = "toggle" ]; then
  if ip link show "$INTERFACE" >/dev/null 2>&1; then
    pkexec wg-quick down "$INTERFACE"
  else
    pkexec wg-quick up "$INTERFACE"
  fi
  exit 0
fi

if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
  echo "{\"text\": \"Not Connected\", \"tooltip\": \"WireGuard is down\", \"alt\": \"disconnected\", \"class\": \"disconnected\"}"
  exit 0
fi

echo "{\"text\": \"Connected\", \"tooltip\": \"WireGuard connected\", \"alt\": \"connected\", \"class\": \"connected\"}"
exit 0
