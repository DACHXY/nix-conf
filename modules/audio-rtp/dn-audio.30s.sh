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
FFPLAY="@ffplay@"

HOSTS=(@hosts@)
@vars@

RUN_DIR="$HOME/.local/run/dn-audio"
LOG_DIR="$HOME/.local/log/dn-audio"
mkdir -p "$RUN_DIR" "$LOG_DIR"

# ── Helpers ──────────────────────────────────────────────────────────────────
pid_file() { echo "$RUN_DIR/$1.pid"; }
log_file() { echo "$LOG_DIR/$1.log"; }

host_port() { local v="${1//-/_}_port"; echo "${!v}"; }

is_playing() {
  local pf; pf="$(pid_file "$1")"
  [[ -f "$pf" ]] || return 1
  kill -0 "$(cat "$pf")" 2>/dev/null
}

playing_host() {
  local h
  for h in "${HOSTS[@]}"; do is_playing "$h" && { echo "$h"; return 0; }; done
  return 1
}

# The SDP must match the sender: payload 97, opus/48000/2.
# `c=` MUST be 0.0.0.0: ffmpeg's RTP demuxer binds that address, so putting
# the sender's IP there makes the receiver try to bind a foreign address
# ("bind failed: Can't assign requested address") and the sender's own IP is
# not reachable as a local bind either. 0.0.0.0 = bind every interface.
write_sdp() {
  local f="$RUN_DIR/$1.sdp"
  cat > "$f" <<-SDP
v=0
o=- 0 0 IN IP4 0.0.0.0
s=dn-audio-$1
c=IN IP4 0.0.0.0
t=0 0
m=audio $2 RTP/AVP 97
b=AS:128
a=rtpmap:97 opus/48000/2
a=fmtp:97 sprop-stereo=1
SDP
  echo "$f"
}

stop() {
  local pf; pf="$(pid_file "$1")"
  [[ -f "$pf" ]] || return 0
  kill "$(cat "$pf")" 2>/dev/null || true
  rm -f "$pf"
}

stop_all() { local h; for h in "${HOSTS[@]}"; do stop "$h"; done; }

# Only one source at a time — you cannot usefully listen to two.
start() {
  local h="$1" sdp
  stop_all
  sdp="$(write_sdp "$h" "$(host_port "$h")")"
  nohup "$FFPLAY" -nodisp -hide_banner -loglevel warning \
    -fflags nobuffer -flags low_delay -framedrop -sync ext \
    -protocol_whitelist file,udp,rtp -i "$sdp" \
    >"$(log_file "$h")" 2>&1 &
  echo $! > "$(pid_file "$h")"
}

# ── Dispatch action if called with arguments ─────────────────────────────────
if [[ $# -ge 1 ]]; then
  case "$1" in
    start)    start "$2" ;;
    stop)     stop "$2" ;;
    stop_all) stop_all ;;
  esac
  sleep 1
  open "swiftbar://refreshplugin?name=dn-audio" 2>/dev/null || true
  exit 0
fi

# ── Build SwiftBar output ────────────────────────────────────────────────────
SELF="${SWIFTBAR_PLUGIN_PATH:-}"
[[ -z "$SELF" ]] && SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

if current="$(playing_host)"; then
  echo "♪ $current | color=primary sfimage=waveform"
else
  echo "♪ | color=gray sfimage=waveform.slash"
fi
echo "---"

for h in "${HOSTS[@]}"; do
  if is_playing "$h"; then
    echo "$h ● | color=primary bash='${SELF}' param1=stop param2='${h}' terminal=false refresh=true sfimage=stop.fill"
    echo "-- Stop | color=#fc5b5b bash='${SELF}' param1=stop param2='${h}' terminal=false refresh=true sfimage=stop.fill"
  else
    echo "$h | bash='${SELF}' param1=start param2='${h}' terminal=false refresh=true sfimage=play.fill"
    echo "-- Listen | bash='${SELF}' param1=start param2='${h}' terminal=false refresh=true sfimage=play.fill"
  fi
done

echo "---"
if playing_host >/dev/null; then
  echo "Stop | color=#fc5b5b bash='${SELF}' param1=stop_all terminal=false refresh=true sfimage=stop.circle"
fi
echo "Refresh | refresh=true sfimage=arrow.2.circlepath"
echo "Logs: ${LOG_DIR} | size=11 color=gray"
