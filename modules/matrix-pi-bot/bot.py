#!/usr/bin/env python3
"""Bridge a Matrix room to a pi coding agent.

One Matrix user (the bot) listens in the rooms it was invited to.  Every text
message from an allowed sender is turned into a one-shot pi run
(`pi --mode json -p`), and the agent's final answer is posted back into the
room.  Each room keeps its own pi session, so the conversation has memory
between messages; `!new` starts a fresh session and `!stop` interrupts a
running turn.

Configuration is entirely through the environment (the NixOS module in
modules/nixosModules/matrix-pi-bot.nix sets it):

  MATRIX_HOMESERVER   e.g. https://matrix.dnywe.com
  MATRIX_USER_ID      the bot's own id, e.g. @pi:dnywe.com
  MATRIX_TOKEN_FILE   file holding the bot's access token
  MATRIX_ALLOWED_USERS  comma separated ids; empty = nobody (safe default)
  MATRIX_ALLOWED_ROOMS  comma separated room ids; empty = any joined room
  MATRIX_WORKSPACE    cwd for the agent
  MATRIX_STATE_DIR    where sync tokens + pi sessions live
  PI_BIN / PI_ARGS    agent binary and extra flags
  PI_TIMEOUT_SECONDS  hard wall clock limit per turn

The bot is deliberately NOT end-to-end encrypted: it only works in
unencrypted rooms.  Anyone who can post in an allowed room can make the agent
run tools on this machine, which is why ALLOWED_USERS is a whitelist.
"""

from __future__ import annotations

import asyncio
import contextlib
import html
import json
import logging
import os
import re
import shlex
import signal
import sys
import time
from pathlib import Path
from typing import Any

from nio import (
    AsyncClient,
    InviteMemberEvent,
    RoomMessageText,
    SyncError,
    WhoamiResponse,
)

LOG = logging.getLogger("matrix-pi-bot")


def _env(name: str, default: str | None = None) -> str:
    value = os.environ.get(name, default)
    if value is None:
        LOG.error("missing required environment variable %s", name)
        sys.exit(2)
    return value


def _split(name: str) -> list[str]:
    return [item.strip() for item in _env(name, "").split(",") if item.strip()]


HOMESERVER = _env("MATRIX_HOMESERVER")
USER_ID = _env("MATRIX_USER_ID")
TOKEN_FILE = Path(_env("MATRIX_TOKEN_FILE"))
ALLOWED_USERS = set(_split("MATRIX_ALLOWED_USERS"))
ALLOWED_ROOMS = set(_split("MATRIX_ALLOWED_ROOMS"))
WORKSPACE = _env("MATRIX_WORKSPACE", os.getcwd())
STATE_DIR = Path(_env("MATRIX_STATE_DIR", "/var/lib/matrix-pi-bot"))
SESSIONS_DIR = Path(_env("MATRIX_SESSIONS_DIR", str(STATE_DIR / "sessions")))
PI_BIN = _env("PI_BIN", "pi")
PI_ARGS = shlex.split(_env("PI_ARGS", ""))
TIMEOUT_SECONDS = int(_env("PI_TIMEOUT_SECONDS", "900"))
MAX_CHARS = int(_env("MATRIX_MAX_CHARS", "6000"))
PROGRESS_INTERVAL = float(_env("PROGRESS_INTERVAL_SECONDS", "3"))
STEP_SECONDS = int(_env("MATRIX_STEP_SECONDS", "30"))
# Live "typewriter" output: the answer message is edited in place while pi runs.
STREAM_ENABLED = _env("MATRIX_STREAM", "1").lower() not in {"0", "false", "no", "off"}
STREAM_INTERVAL = float(_env("MATRIX_STREAM_INTERVAL", "2"))
HEARTBEAT_SECONDS = float(_env("MATRIX_HEARTBEAT", "20"))
# `pi --mode json` frames its events line by line, and message_start carries the
# whole system prompt — well past asyncio's 64 KiB default readline limit.
EVENT_LINE_LIMIT = int(_env("MATRIX_EVENT_LINE_LIMIT", str(16 * 1024 * 1024)))

HELP_TEXT = f"""\
pi bridge — talk to a coding agent from this room.

• send any message: it is handed to `pi -p` in `{WORKSPACE}`; the answer comes back here
• `!new`   start a fresh session for this room (forget the previous context)
• `!stop`  interrupt the turn that is currently running
• `!status` show the session, model flags and workspace
• `!help`  this text

Notes: sessions are per room; the agent runs with the tools this service was
granted, so treat it like a shell on that machine."""


# --------------------------------------------------------------------------- #
# state
# --------------------------------------------------------------------------- #
class State:
    """Small JSON file: sync token, per-room session counters, warning cooldown."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self.data: dict[str, Any] = {"since": None, "rooms": {}, "warned": {}}
        try:
            self.data.update(json.loads(path.read_text()))
        except FileNotFoundError:
            pass
        except (OSError, ValueError) as exc:
            LOG.warning("ignoring unreadable state file %s: %s", path, exc)
        self.data.setdefault("rooms", {})
        self.data.setdefault("warned", {})

    def save(self) -> None:
        tmp = self.path.with_suffix(".tmp")
        try:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            tmp.write_text(json.dumps(self.data, indent=2, sort_keys=True))
            tmp.replace(self.path)
        except OSError as exc:
            LOG.warning("could not save state: %s", exc)

    # -- sessions ---------------------------------------------------------- #
    def session_id(self, room_id: str) -> str:
        room = self.data["rooms"].get(room_id)
        if not room:
            room = {"n": 0}
            self.data["rooms"][room_id] = room
            self.save()
        return f"matrix-{room_id.split(':')[0].lstrip('!')}-{room['n']}"

    def reset_session(self, room_id: str) -> str:
        room = self.data["rooms"].setdefault(room_id, {"n": 0})
        room["n"] += 1
        self.save()
        return self.session_id(room_id)

    # -- warning cooldown --------------------------------------------------- #
    def should_warn(self, sender: str, window: int = 600) -> bool:
        now = time.time()
        last = self.data["warned"].get(sender, 0)
        if now - last < window:
            return False
        self.data["warned"][sender] = now
        self.save()
        return True


# --------------------------------------------------------------------------- #
# markdown -> matrix html
# --------------------------------------------------------------------------- #
_FENCE = re.compile(r"```([\w.+-]*)\n(.*?)```", re.S)


def _inline(text: str) -> str:
    out = html.escape(text)
    out = re.sub(r"`([^`\n]+)`", r"<code>\1</code>", out)
    out = re.sub(r"\*\*([^*\n]+)\*\*", r"<b>\1</b>", out)
    return out.replace("\n", "<br>")


def md_to_html(text: str) -> str:
    parts: list[str] = []
    pos = 0
    for match in _FENCE.finditer(text):
        parts.append(_inline(text[pos : match.start()]))
        lang = match.group(1)
        body = html.escape(match.group(2))
        cls = f' class="language-{lang}"' if lang else ""
        parts.append(f"<pre><code{cls}>{body}</code></pre>")
        pos = match.end()
    parts.append(_inline(text[pos:]))
    return "".join(parts)


def chunk(text: str, limit: int = MAX_CHARS) -> list[str]:
    """Split long answers on line boundaries so Matrix stays readable."""
    if len(text) <= limit:
        return [text]
    chunks: list[str] = []
    current = ""
    for line in text.splitlines(keepends=True):
        if len(current) + len(line) > limit and current:
            chunks.append(current)
            current = ""
        while len(line) > limit:  # a single gigantic line
            chunks.append(line[:limit])
            line = line[limit:]
        current += line
    if current:
        chunks.append(current)
    return chunks or [text]


# --------------------------------------------------------------------------- #
# pi runner
# --------------------------------------------------------------------------- #
class PiRun:
    """One `pi --mode json -p` invocation, parsed as it streams."""

    def __init__(self, prompt: str, session_id: str) -> None:
        self.prompt = prompt
        self.session_id = session_id
        self.text = ""
        self.blocks: list[str] = []
        self.thinking_chars = 0
        self.error = ""
        self.proc: asyncio.subprocess.Process | None = None
        self.timed_out = False

    @property
    def cmd(self) -> list[str]:
        return [
            PI_BIN,
            "--mode",
            "json",
            "-p",
            "--session-dir",
            str(SESSIONS_DIR),
            "--session-id",
            self.session_id,
            *PI_ARGS,
            "--",
            self.prompt,
        ]

    async def run(self, on_progress, on_stream) -> str:
        SESSIONS_DIR.mkdir(parents=True, exist_ok=True)
        LOG.info("running %s (session %s)", shlex.join(self.cmd[:6]), self.session_id)
        self.proc = await asyncio.create_subprocess_exec(
            *self.cmd,
            cwd=WORKSPACE,
            stdin=asyncio.subprocess.DEVNULL,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            start_new_session=True,
            limit=EVENT_LINE_LIMIT,
        )
        readers = [
            asyncio.create_task(self._read_stdout(on_progress, on_stream)),
            asyncio.create_task(self._read_stderr()),
        ]
        try:
            await asyncio.wait_for(self.proc.wait(), TIMEOUT_SECONDS)
        except asyncio.TimeoutError:
            self.timed_out = True
            LOG.warning("turn exceeded %ss, killing it", TIMEOUT_SECONDS)
            await self._kill()
        await asyncio.gather(*readers, return_exceptions=True)
        if not self.text and not self.error:
            self.error = (
                f"pi exited with code {self.proc.returncode} and produced no output"
            )
        if self.timed_out:
            note = f"\n\n_(stopped after {TIMEOUT_SECONDS}s; the turn was killed)_"
            self.text = (self.text + note) if self.text else note.strip()
        return self.text or self.error

    async def _kill(self) -> None:
        if self.proc is None:
            return
        try:
            os.killpg(os.getpgid(self.proc.pid), signal.SIGTERM)
        except ProcessLookupError:
            return
        try:
            await asyncio.wait_for(self.proc.wait(), 10)
        except asyncio.TimeoutError:
            try:
                os.killpg(os.getpgid(self.proc.pid), signal.SIGKILL)
            except ProcessLookupError:
                pass

    async def _read_stderr(self) -> None:
        assert self.proc is not None and self.proc.stderr is not None
        tail: list[str] = []
        async for raw in self.proc.stderr:
            line = raw.decode("utf-8", "replace").rstrip()
            if not line:
                continue
            tail.append(line)
            del tail[:-20]
        if tail:
            LOG.debug("pi stderr: %s", " | ".join(tail))
            self.error = tail[-1]

    def stream_text(self) -> str:
        """Text produced so far in this turn (preview while the turn runs)."""
        return "\n\n".join(block for block in self.blocks if block.strip()).strip()

    async def _on_stream_event(self, event: dict[str, Any], on_stream) -> None:
        try:
            preview = self._accumulate(event)
        except Exception:  # noqa: BLE001 - never kill the stdout reader
            LOG.debug("unparsable stream event", exc_info=True)
            return
        if not preview:
            return
        try:
            await on_stream(preview)
        except Exception:  # noqa: BLE001 - a failed edit must not kill the turn
            LOG.debug("stream callback failed", exc_info=True)

    def _accumulate(self, event: dict[str, Any]) -> str:
        update = event.get("assistantMessageEvent") or {}
        kind = update.get("type")
        if kind == "text_start":
            self.blocks.append("")
        elif kind == "text_delta":
            if not self.blocks:
                self.blocks.append("")
            self.blocks[-1] += str(update.get("delta") or "")
        elif kind == "text_end":
            final = update.get("text") or update.get("content") or ""
            if isinstance(final, str) and final:
                if not self.blocks:
                    self.blocks.append("")
                self.blocks[-1] = final
        else:
            return ""
        return self.stream_text()

    async def _read_stdout(self, on_progress, on_stream) -> None:
        assert self.proc is not None and self.proc.stdout is not None
        try:
            async for raw in self.proc.stdout:
                await self._handle_line(raw, on_progress, on_stream)
        except asyncio.CancelledError:
            raise
        except Exception:  # noqa: BLE001 - a dead reader would block pi on write
            LOG.exception("event stream broke; killing the turn")
            self.error = self.error or "pi event stream broke (unreadable output)"
            await self._kill()

    async def _handle_line(self, raw: bytes, on_progress, on_stream) -> None:
        line = raw.decode("utf-8", "replace").strip()
        if not line.startswith("{"):
            return
        try:
            event = json.loads(line)
        except ValueError:
            return
        kind = event.get("type")
        if kind == "message_update":
            update = event.get("assistantMessageEvent") or {}
            if update.get("type") == "thinking_delta":
                self.thinking_chars += len(str(update.get("delta") or ""))
                await on_progress(f"🧠 thinking… {self.thinking_chars} chars")
            else:
                await self._on_stream_event(event, on_stream)
        elif kind == "message_end":
            text = _message_text(event.get("message") or {})
            if text:
                self.text = text
        elif kind == "turn_end":
            text = _message_text(event.get("message") or {})
            if text:
                self.text = text
        elif kind == "tool_execution_start":
            await on_progress(f"🔧 {event.get('toolName', 'tool')}")
        elif kind == "auto_retry_start":
            await on_progress(f"↻ retry {event.get('attempt')}/{event.get('maxAttempts')}")
        elif kind == "error":
            message = event.get("message") or event.get("error")
            if message:
                self.error = str(message)
        elif kind == "extension_error":
            self.error = str(event.get("error", "extension error"))
        elif kind == "agent_settled":
            LOG.debug("agent settled (aborted=%s)", event.get("aborted"))


def _message_text(message: dict[str, Any]) -> str:
    if message.get("role") != "assistant":
        return ""
    parts = [
        block.get("text", "")
        for block in message.get("content") or []
        if isinstance(block, dict) and block.get("type") == "text"
    ]
    return "".join(parts).strip()


# --------------------------------------------------------------------------- #
# bot
# --------------------------------------------------------------------------- #
class Bot:
    def __init__(self) -> None:
        self.state = State(STATE_DIR / "state.json")
        self.client = AsyncClient(HOMESERVER, USER_ID)
        self.tasks: dict[str, asyncio.Task] = {}
        self.runs: dict[str, PiRun] = {}
        self._stop = asyncio.Event()
        self._closing = False
        self.sync_task: asyncio.Task | None = None

    # -- plumbing ---------------------------------------------------------- #
    async def send(
        self, room_id: str, text: str, *, html_body: str | None = None, notice: bool = False
    ) -> str | None:
        content: dict[str, Any] = {"msgtype": "m.text", "body": text}
        if notice:
            content["msgtype"] = "m.notice"
        if html_body:
            content["format"] = "org.matrix.custom.html"
            content["formatted_body"] = html_body
        response = await self.client.room_send(room_id, "m.room.message", content)
        event_id = getattr(response, "event_id", None)
        if event_id is None:
            LOG.warning("send to %s failed: %s", room_id, response)
        return event_id

    async def send_agent_text(self, room_id: str, text: str) -> None:
        for piece in chunk(text):
            await self.send(room_id, piece, html_body=md_to_html(piece))

    async def edit(
        self, room_id: str, event_id: str, text: str, *, notice: bool = True
    ) -> None:
        msgtype = "m.notice" if notice else "m.text"
        await self.client.room_send(
            room_id,
            "m.room.message",
            {
                "msgtype": msgtype,
                "body": f"* {text}",
                "format": "org.matrix.custom.html",
                "formatted_body": f"* {_inline(text)}" if notice else md_to_html(text),
                "m.new_content": {
                    "msgtype": msgtype,
                    "body": text,
                    "format": "org.matrix.custom.html",
                    "formatted_body": _inline(text) if notice else md_to_html(text),
                },
                "m.relates_to": {"rel_type": "m.replace", "event_id": event_id},
            },
        )

    async def react(self, room_id: str, event_id: str, key: str) -> None:
        await self.client.room_send(
            room_id,
            "m.reaction",
            {"m.relates_to": {"rel_type": "m.annotation", "event_id": event_id, "key": key}},
        )

    # -- main loop --------------------------------------------------------- #
    async def start(self) -> None:
        token = TOKEN_FILE.read_text().strip()
        if not token:
            raise SystemExit(f"access token file {TOKEN_FILE} is empty")
        self.client.access_token = token
        self.client.user_id = USER_ID
        whoami = await self.client.whoami()
        if not isinstance(whoami, WhoamiResponse):
            await self.client.close()
            raise SystemExit(f"token rejected by {HOMESERVER}: {whoami}")
        LOG.info(
            "logged in as %s (%s), rooms=%s, users=%s",
            whoami.user_id,
            HOMESERVER,
            sorted(ALLOWED_ROOMS) or "*",
            sorted(ALLOWED_USERS) or "none",
        )
        self.sync_task = asyncio.create_task(self._sync_loop())
        try:
            await self.sync_task
        except asyncio.CancelledError:
            pass
        LOG.info("bridge stopped")

    async def _sync_loop(self) -> None:
        while not self._stop.is_set():
            try:
                await self.sync_once()
            except asyncio.CancelledError:
                raise
            except Exception:  # noqa: BLE001 - keep the bridge alive
                if self._stop.is_set():
                    break
                LOG.exception("sync failed, retrying in 15s")
                await asyncio.sleep(15)
        LOG.info("sync loop stopped")

    async def sync_once(self) -> None:
        response = await self.client.sync(
            timeout=STEP_SECONDS * 1000, since=self.state.data.get("since")
        )
        if isinstance(response, SyncError):
            LOG.warning("sync error: %s", response)
            await asyncio.sleep(10)
            return
        self.state.data["since"] = response.next_batch
        self.state.save()
        for room_id, invited in response.rooms.invite.items():
            await self.on_invite(room_id, invited)
        cutoff = time.time() - 120
        for room_id, joined in response.rooms.join.items():
            for event in joined.timeline.events:
                if not isinstance(event, RoomMessageText):
                    continue
                if (event.server_timestamp or 0) / 1000 < cutoff:
                    continue  # backlog from before the bot started
                await self.on_message(room_id, event)

    async def on_invite(self, room_id: str, invited: Any) -> None:
        senders = {
            event.sender
            for event in invited.events
            if isinstance(event, InviteMemberEvent) and event.state_key == USER_ID
        }
        if ALLOWED_USERS and not (senders & ALLOWED_USERS):
            LOG.warning("ignoring invite to %s from %s", room_id, senders)
            await self.client.room_leave(room_id)
            return
        LOG.info("joining %s", room_id)
        await self.client.join(room_id)
        await self.send(room_id, "pi bridge connected. " + HELP_TEXT, notice=True)

    async def on_message(self, room_id: str, event: RoomMessageText) -> None:
        if event.sender == self.client.user_id:
            return
        body = (event.body or "").strip()
        if not body:
            return
        command = body.lower()
        if ALLOWED_ROOMS and room_id not in ALLOWED_ROOMS:
            return
        if ALLOWED_USERS and event.sender not in ALLOWED_USERS:
            if self.state.should_warn(event.sender):
                await self.send(room_id, f"{event.sender} is not allowed to use this agent.", notice=True)
            return

        # commands are handled even while a turn is running
        if command in {"!help", "/help"}:
            await self.send(room_id, HELP_TEXT, notice=True)
            return
        if command in {"!status", "/status"}:
            running = room_id in self.tasks and not self.tasks[room_id].done()
            await self.send(
                room_id,
                f"session `{self.state.session_id(room_id)}`, "
                f"workspace `{WORKSPACE}`, flags `{shlex.join(PI_ARGS) or '-'}`, "
                f"running: {'yes' if running else 'no'}",
                html_body=f"session <code>{self.state.session_id(room_id)}</code>, "
                f"workspace <code>{WORKSPACE}</code>, "
                f"flags <code>{html.escape(shlex.join(PI_ARGS) or '-')}</code>, "
                f"running: {'yes' if running else 'no'}",
                notice=True,
            )
            return
        if command in {"!new", "/new"}:
            await self.cancel(room_id)
            session = self.state.reset_session(room_id)
            await self.send(room_id, f"Fresh session `{session}`.", notice=True)
            return
        if command in {"!stop", "/stop"}:
            stopped = await self.cancel(room_id)
            await self.send(room_id, "Stopped." if stopped else "Nothing is running.", notice=True)
            return

        if room_id in self.tasks and not self.tasks[room_id].done():
            await self.send(room_id, "Still working on the previous message — `!stop` cancels it.", notice=True)
            return
        self.tasks[room_id] = asyncio.create_task(self.turn(room_id, body, event.event_id))

    async def cancel(self, room_id: str) -> bool:
        """Kill the running turn for a room (if any) and forget its task."""
        task = self.tasks.pop(room_id, None)
        run = self.runs.pop(room_id, None)
        if run is not None:
            await run._kill()  # noqa: SLF001 - the bot owns the run
        if task is None or task.done():
            return run is not None
        task.cancel()
        with contextlib.suppress(BaseException):
            await task
        return True

    async def turn(self, room_id: str, prompt: str, event_id: str) -> None:
        await self.react(room_id, event_id, "⏳")
        status_id = await self.send(room_id, "⏳ working…", notice=True)
        last_update = 0.0

        async def progress(text: str) -> None:
            nonlocal last_update
            now = time.time()
            if status_id and now - last_update >= PROGRESS_INTERVAL:
                last_update = now
                await self.edit(room_id, status_id, text)

        run = PiRun(prompt, self.state.session_id(room_id))
        self.runs[room_id] = run
        started = time.time()
        stream_id: str | None = None
        last_stream = 0.0

        async def stream(text: str) -> None:
            """Show the answer growing: one message, edited in place."""
            nonlocal stream_id, last_stream
            if not STREAM_ENABLED:
                return
            now = time.time()
            if stream_id is not None and now - last_stream < STREAM_INTERVAL:
                return
            body = text[:MAX_CHARS]
            last_stream = now
            if stream_id is None:
                stream_id = await self.send(room_id, body, html_body=md_to_html(body))
            else:
                await self.edit(room_id, stream_id, body, notice=False)

        async def heartbeat() -> None:
            """Keep the status line moving so a quiet model call never looks dead."""
            while True:
                await asyncio.sleep(HEARTBEAT_SECONDS)
                if not status_id:
                    continue
                waited = int(time.time() - started)
                with contextlib.suppress(Exception):
                    await self.edit(room_id, status_id, f"⏳ still working… {waited}s")

        beat = asyncio.create_task(heartbeat())
        try:
            answer = await run.run(progress, stream)
        except asyncio.CancelledError:
            # cancel() already killed the process tree; nothing to await here.
            raise
        except Exception as exc:  # noqa: BLE001
            LOG.exception("turn failed")
            answer = f"Internal error: {exc}"
        finally:
            self.runs.pop(room_id, None)
            beat.cancel()
            with contextlib.suppress(BaseException):
                await beat
        elapsed = int(time.time() - started)
        if status_id:
            await self.edit(room_id, status_id, f"done in {elapsed}s")
        if stream_id:
            # The streamed message is the answer: finish it with the final text.
            await self.edit(room_id, stream_id, answer[:MAX_CHARS], notice=False)
            if len(answer) > MAX_CHARS:
                await self.send_agent_text(room_id, answer[MAX_CHARS:])
        else:
            await self.send_agent_text(room_id, answer)
        ok = not run.error or bool(run.text)
        await self.react(room_id, event_id, "✅" if ok else "⚠️")

    async def close(self) -> None:
        """Stop the sync loop and shut the Matrix client down (signal handler)."""
        if self._closing:
            return
        self._closing = True
        self._stop.set()
        task = self.sync_task
        if task is not None and not task.done():
            task.cancel()
            with contextlib.suppress(BaseException):
                await task
        for room_id in list(self.tasks):
            await self.cancel(room_id)
        await self.client.close()


async def amain() -> int:
    logging.basicConfig(
        level=os.environ.get("LOG_LEVEL", "INFO").upper(),
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        stream=sys.stderr,
    )
    # nio logs every state event at INFO; keep our own lines readable.
    logging.getLogger("nio").setLevel(logging.WARNING)
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    bot = Bot()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, lambda: loop.create_task(bot.close()))
    try:
        await bot.start()
    except (KeyboardInterrupt, asyncio.CancelledError):
        pass
    finally:
        with contextlib.suppress(Exception):
            await bot.close()
    return 0


def main() -> int:
    try:
        return asyncio.run(amain())
    except SystemExit as exc:
        LOG.error("%s", exc)
        return 1


if __name__ == "__main__":
    sys.exit(main())
