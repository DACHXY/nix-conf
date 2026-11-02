#!/usr/bin/env python3
"""Now Playing metadata for the dn-audio-rtp sender.

Serves, on metaPort (plain HTTP/1.1, netbird interface only):

  GET  /nowplaying       JSON snapshot of the default MPRIS player
  GET  /art?id=<artId>   the cover art, jpeg, longest side <= 512 px
  POST /control/<action> play-pause | next | previous -> playerctl

The Mac receiver polls /nowplaying once a second while it is listening to
this host and pulls /art when artId changes. artId is the sha1 of the art
URL, so /art is immutable and can be cached by the receiver forever.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import tempfile
import threading
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, unquote, urlparse

# Unit separator: player metadata routinely contains "|" but never 0x1f.
SEP = "\x1f"
FMT = SEP.join(
    [
        "{{status}}",
        "{{playerName}}",
        "{{xesam:title}}",
        "{{xesam:artist}}",
        "{{xesam:album}}",
        "{{mpris:length}}",
        "{{position}}",
        "{{mpris:artUrl}}",
    ]
)

ACTIONS = {"play-pause", "next", "previous"}
ART_ID_RE = re.compile(r"^[0-9a-f]{40}$")
CACHE_MAX = 20
PLAYERCTL_TIMEOUT = 2

CACHE_DIR = os.path.join(
    os.environ.get("XDG_RUNTIME_DIR") or tempfile.gettempdir(), "dn-audio-nowplaying"
)

_convert_lock = threading.Lock()
_inflight = set()
_state_lock = threading.Lock()


def none_state():
    return {
        "status": "None",
        "player": "",
        "title": "",
        "artist": "",
        "album": "",
        "lengthMs": None,
        "positionMs": None,
        "artId": "",
        "_artUrl": "",
    }


def to_ms(value):
    """playerctl prints microseconds; the wire format is milliseconds."""
    try:
        us = int(float(value))
    except (TypeError, ValueError):
        return None
    return us // 1000


def query_state():
    """Ask playerctl for the preferred player (the one Playing, most recent)."""
    try:
        proc = subprocess.run(
            ["playerctl", "metadata", "--format", FMT],
            capture_output=True,
            text=True,
            timeout=PLAYERCTL_TIMEOUT,
        )
    except (OSError, subprocess.TimeoutExpired):
        return none_state()
    out = proc.stdout.rstrip("\n")
    if proc.returncode != 0 or not out:
        return none_state()

    fields = out.split(SEP)
    fields += [""] * (8 - len(fields))
    status, player, title, artist, album, length, position, art_url = fields[:8]

    if status not in ("Playing", "Paused", "Stopped"):
        status = "Stopped"
    art_id = hashlib.sha1(art_url.encode()).hexdigest() if art_url else ""
    return {
        "status": status,
        "player": player,
        "title": title,
        "artist": artist,
        "album": album,
        "lengthMs": to_ms(length),
        "positionMs": to_ms(position),
        "artId": art_id,
        "_artUrl": art_url,
    }


def public(state):
    return {k: v for k, v in state.items() if not k.startswith("_")}


def art_path(art_id):
    return os.path.join(CACHE_DIR, art_id + ".jpg")


def prune():
    """Keep only the newest CACHE_MAX covers."""
    try:
        entries = [
            os.path.join(CACHE_DIR, f) for f in os.listdir(CACHE_DIR) if f.endswith(".jpg")
        ]
    except OSError:
        return
    if len(entries) <= CACHE_MAX:
        return
    entries.sort(key=lambda p: os.path.getmtime(p), reverse=True)
    for stale in entries[CACHE_MAX:]:
        try:
            os.unlink(stale)
        except OSError:
            pass


def read_source(art_url):
    if art_url.startswith("file://"):
        with open(unquote(urlparse(art_url).path), "rb") as fh:
            return fh.read()
    with urllib.request.urlopen(art_url, timeout=5) as resp:
        return resp.read()


def convert(art_url, art_id):
    """Rasterize art_url into <cache>/<artId>.jpg. Returns the path or None."""
    try:
        raw = read_source(art_url)
        proc = subprocess.run(
            ["magick", "-", "-resize", "512x512>", "-quality", "85", "jpeg:-"],
            input=raw,
            capture_output=True,
            timeout=15,
        )
        if proc.returncode != 0 or not proc.stdout:
            return None
        os.makedirs(CACHE_DIR, exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=CACHE_DIR, suffix=".part")
        with os.fdopen(fd, "wb") as fh:
            fh.write(proc.stdout)
        os.replace(tmp, art_path(art_id))
        prune()
        return art_path(art_id)
    except Exception:
        return None


def convert_async(art_url, art_id):
    with _state_lock:
        if art_id in _inflight or os.path.exists(art_path(art_id)):
            return
        _inflight.add(art_id)

    def work():
        try:
            convert(art_url, art_id)
        finally:
            with _state_lock:
                _inflight.discard(art_id)

    threading.Thread(target=work, daemon=True).start()


def convert_sync(art_url, art_id):
    """Serialized conversion; a background thread may be doing the same one."""
    with _convert_lock:
        if os.path.exists(art_path(art_id)):
            return art_path(art_id)
        return convert(art_url, art_id)


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "dn-audio-nowplaying"

    def log_message(self, fmt, *args):  # journald already timestamps us
        pass

    def send_json(self, code, payload):
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_error_json(self, code, message):
        self.send_json(code, {"error": message})

    def route(self):
        return urlparse(self.path)

    def do_GET(self):
        try:
            url = self.route()
            if url.path == "/nowplaying":
                self.handle_nowplaying()
            elif url.path == "/art":
                self.handle_art(url)
            else:
                self.send_error_json(404, "not found")
        except Exception as exc:  # keep the service alive on bad input
            self.send_error_json(500, str(exc))

    def do_POST(self):
        try:
            url = self.route()
            if not url.path.startswith("/control/"):
                self.send_error_json(404, "not found")
                return
            action = url.path[len("/control/") :]
            if action not in ACTIONS:
                self.send_error_json(404, "unknown action")
                return
            subprocess.run(
                ["playerctl", action],
                capture_output=True,
                timeout=PLAYERCTL_TIMEOUT,
            )
            self.send_response(204)
            self.send_header("Content-Length", "0")
            self.end_headers()
        except Exception as exc:
            self.send_error_json(500, str(exc))

    def handle_nowplaying(self):
        state = query_state()
        if state["artId"]:
            convert_async(state["_artUrl"], state["artId"])
        self.send_json(200, public(state))

    def handle_art(self, url):
        art_id = (parse_qs(url.query).get("id") or [""])[0]
        if not ART_ID_RE.match(art_id):
            self.send_error_json(404, "unknown art")
            return
        path = art_path(art_id)
        if not os.path.exists(path):
            # Only the current cover may be rasterized on demand; anything else
            # is a stale cache miss.
            state = query_state()
            if state["artId"] != art_id or not state["_artUrl"]:
                self.send_error_json(404, "unknown art")
                return
            path = convert_sync(state["_artUrl"], art_id)
            if not path:
                self.send_error_json(404, "art unavailable")
                return
        with open(path, "rb") as fh:
            body = fh.read()
        self.send_response(200)
        self.send_header("Content-Type", "image/jpeg")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "max-age=86400")
        self.end_headers()
        self.wfile.write(body)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--port", type=int, required=True, help="TCP port to listen on")
    parser.add_argument("--bind", default="", help="address to bind (default: all)")
    args = parser.parse_args()

    os.makedirs(CACHE_DIR, exist_ok=True)
    server = ThreadingHTTPServer((args.bind, args.port), Handler)
    server.daemon_threads = True
    server.serve_forever()


if __name__ == "__main__":
    main()
