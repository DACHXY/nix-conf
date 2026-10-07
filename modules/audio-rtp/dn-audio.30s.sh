#!/usr/bin/env bash
# <xbar.title>dn audio</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.desc>Listen to another machine's system audio over RTP</xbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>false</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

# Rendered by modules/audio-rtp.nix — edit that file, not this one.
set -uo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
MPV="@mpv@"

HOSTS=(@hosts@)
@vars@

RUN_DIR="$HOME/.local/run/dn-audio"
LOG_DIR="$HOME/.local/log/dn-audio"
mkdir -p "$RUN_DIR" "$LOG_DIR"

# ── Helpers ──────────────────────────────────────────────────────────────────
pid_file() { echo "$RUN_DIR/$1.pid"; }
log_file() { echo "$LOG_DIR/$1.log"; }
vol_file() { echo "$RUN_DIR/$1.vol"; }

host_ip() { local v="${1//-/_}_ip"; echo "${!v}"; }
host_port() { local v="${1//-/_}_port"; echo "${!v}"; }

is_playing() {
  local pf; pf="$(pid_file "$1")"
  [[ -f "$pf" ]] || return 1
  kill -0 "$(cat "$pf")" 2>/dev/null
}

playing_hosts() {
  local h
  for h in "${HOSTS[@]}"; do is_playing "$h" && echo "$h"; done
}

ipc_file() { echo "$RUN_DIR/$1.sock"; }

# Send one JSON command to the running mpv and print its replies.
mpv_cmd() {
  local s; s="$(ipc_file "$1")"
  [[ -S "$s" ]] || return 1
  printf '%s\n' "$2" | nc -U -w 2 "$s" 2>/dev/null
}

# Live volume: mpv is driven over its JSON IPC socket, so changing the volume
# never restarts the stream. The file is only the startup level for the next
# start.
get_vol() {
  local v f
  v="$(mpv_cmd "$1" '{"command":["get_property","volume"]}' \
        | sed -n 's/.*"data":\([0-9][0-9.]*\).*/\1/p' | head -1)"
  if [[ -n "$v" ]]; then printf '%.0f\n' "$v"; return; fi
  f="$(vol_file "$1")"
  [[ -f "$f" ]] && cat "$f" || echo 100
}

set_vol() {
  local h="$1" v="$2"
  (( v < 0 )) && v=0
  (( v > 100 )) && v=100
  echo "$v" > "$(vol_file "$h")"
  mpv_cmd "$h" "{\"command\":[\"set_property\",\"volume\",$v]}" >/dev/null
}

# The SDP must match the sender: payload 97, opus/48000/2.
# c= must be 0.0.0.0: the player binds its listen socket to the c= address, so
# the sender's IP here makes it fail with "Can't assign requested address".
write_sdp() {
  local f="$RUN_DIR/$1.sdp"
  cat > "$f" <<-SDP
v=0
o=- 0 0 IN IP4 $2
s=dn-audio-$1
c=IN IP4 0.0.0.0
t=0 0
m=audio $3 RTP/AVP 97
b=AS:128
a=rtpmap:97 opus/48000/2
a=fmtp:97 sprop-stereo=1
SDP
  echo "$f"
}

stop() {
  local pf pid; pf="$(pid_file "$1")"
  [[ -f "$pf" ]] || return 0
  pid="$(cat "$pf")"
  kill "$pid" 2>/dev/null || true
  # Wait for the UDP port to be released, else a restart hits "Address already in use".
  for _ in {1..20}; do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
  rm -f "$pf" "$(ipc_file "$1")"
}

stop_all() { local h; for h in "${HOSTS[@]}"; do stop "$h"; done; }

# Each host is an independent toggle, so any combination of them can play.
start() {
  local h="$1" sdp sock vol
  # Idempotent: a stale pid file or a double start would otherwise leave an
  # orphan mpv holding the RTP port, and the pid file would point at a dead one.
  stop "$h"
  sdp="$(write_sdp "$h" "$(host_ip "$h")" "$(host_port "$h")")"
  sock="$(ipc_file "$h")"
  vol="$(get_vol "$h")"
  rm -f "$sock"
  nohup "$MPV" --no-video --really-quiet --osc=no \
    --input-ipc-server="$sock" --profile=low-latency --audio-buffer=0.3 \
    --volume="$vol" "$sdp" \
    >"$(log_file "$h")" 2>&1 &
  echo $! > "$(pid_file "$h")"
}

# ── Dispatch action if called with arguments ─────────────────────────────────
if [[ $# -ge 1 ]]; then
  case "$1" in
    start)    start "$2" ;;
    stop)     stop "$2" ;;
    stop_all) stop_all ;;
    vol)      set_vol "$2" "$3" ;;
    vol_step) set_vol "$2" "$(( $(get_vol "$2") + $3 ))" ;;
    # Vee slider: the chosen value arrives as the final argument (and in$VEE_CONTROL_VALUE).
    vol_live) [[ -n "${3:-}" ]] && set_vol "$2" "$3" ;;
    mute)     mpv_cmd "$2" '{"command":["cycle","mute"]}' >/dev/null ;;
  esac
  sleep 0.2
  [[ -z "${VEE:-}" ]] && { open "swiftbar://refreshplugin?name=dn-audio" 2>/dev/null || true; }
  exit 0
fi

# ── Build SwiftBar output ────────────────────────────────────────────────────
SELF="${SWIFTBAR_PLUGIN_PATH:-}"
[[ -z "$SELF" ]] && SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

mapfile -t playing < <(playing_hosts)
if (( ${#playing[@]} )); then
  echo "♪ | color=primary sfimage=waveform"
else
  echo "♪ | color=gray sfimage=waveform.slash"
fi
echo "---"

for h in "${HOSTS[@]}"; do
  if is_playing "$h"; then
    cur="$(get_vol "$h")"
    # The toggle and the volume row are siblings: a row that has children opens
    # its submenu instead of running its own action (Vee and SwiftBar both), so
    # the host row must stay childless or clicking it does nothing. Vee also
    # only attaches slider= to a childless row.
    echo "$h ● | color=primary bash='${SELF}' param1=stop param2='${h}' terminal=false refresh=true sfimage=stop.fill"
    if [[ -n "${VEE:-}" ]]; then
      echo "$h ${cur}% | slider=0,100,$cur bash='${SELF}' param1=vol_live param2='${h}' terminal=false refresh=true sfimage=speaker.wave.2.fill"
    else
      echo "$h ${cur}% | sfimage=speaker.wave.2.fill"
      echo "-- Quieter (-5) | bash='${SELF}' param1=vol_step param2='${h}' param3=-5 terminal=false refresh=true sfimage=speaker.minus.fill"
      echo "-- Louder (+5) | bash='${SELF}' param1=vol_step param2='${h}' param3=5 terminal=false refresh=true sfimage=speaker.plus.fill"
      echo "-- Mute | bash='${SELF}' param1=mute param2='${h}' terminal=false refresh=true sfimage=speaker.slash.fill"
      echo "-- Presets | sfimage=slider.horizontal.3"
      for v in 100 75 50 25 0; do
        mark=""
        [[ "$cur" == "$v" ]] && mark=" ✓"
        echo "---- ${v}%${mark} | bash='${SELF}' param1=vol param2='${h}' param3=$v terminal=false refresh=true"
      done
    fi
  else
    echo "$h | bash='${SELF}' param1=start param2='${h}' terminal=false refresh=true sfimage=play.fill"
  fi
done

echo "---"
echo "Refresh | refresh=true sfimage=arrow.2.circlepath"
