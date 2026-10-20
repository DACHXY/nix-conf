# Stalwart MTA hook (DATA stage) -> Loki on dn-server.
#
# Why this exists: Stalwart's telemetry events never carry the Subject header,
# and reading it back out of the mail store would need a JMAP/IMAP credential
# per account. The MTA hook is the one place where the server hands the whole
# message (envelope + headers + size) to an outside process, so a hook that
# ships the headers to Loki gives "one row per message, with Subject" for every
# account at once, with no credentials and no new network exposure.
#
# The hook only *observes*: the receiver answers `{"action":"accept"}` to
# everything and never inspects the body, and the MtaHook object is created with
# tempFailOnError = false, so a receiver outage cannot refuse mail.
{ config, ... }:
let
  inherit (config.flake.public.config.machines) dn-server;
  inherit (config.flake.public.config.services) loki stalwart;
in
{
  configurations.nixos.dn-cc.module =
    { pkgs, ... }:
    let
      inherit (pkgs) python3;
      port = stalwart.mtaHookPort;
      # Loki's push API, not OTLP: this receiver already has the data in hand and
      # the native API takes structured metadata without a protobuf encoder.
      lokiUrl = "http://${dn-server.ip}:${toString loki.port}/loki/api/v1/push";

      receiver = pkgs.writeText "stalwart-mta-hook.py" ''
        import email.header
        import json
        import os
        import sys
        import time
        import urllib.request
        from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

        PORT = int(os.environ.get("HOOK_PORT", "30097"))
        LOKI_URL = os.environ["LOKI_URL"]
        TIMEOUT = float(os.environ.get("LOKI_TIMEOUT", "3"))
        MAXLEN = 400


        def header_value(headers, name):
            for header in headers or []:
                if not isinstance(header, list) or len(header) != 2:
                    continue
                if str(header[0]).lower() == name:
                    return str(header[1])
            return ""


        def decode(value):
            # RFC 2047 encoded-words ("=?utf-8?B?...?=") are what non-ASCII
            # subjects look like on the wire; decode_header copes with the
            # mixed encoded/plain runs a real Subject contains.
            if not value:
                return ""
            try:
                parts = email.header.decode_header(value)
            except Exception:
                return value
            out = []
            for chunk, charset in parts:
                if isinstance(chunk, bytes):
                    try:
                        out.append(chunk.decode(charset or "utf-8", "replace"))
                    except Exception:
                        out.append(chunk.decode("utf-8", "replace"))
                else:
                    out.append(str(chunk))
            return "".join(out)


        def clip(value):
            text = str(value or "").replace("\r", " ").replace("\n", " ").strip()
            return text[:MAXLEN]


        LISTENER_NAMES = {25: "smtp", 587: "submission", 465: "smtps"}

        def listener_name(port):
            try:
                port = int(port)
            except (TypeError, ValueError):
                return ""
            return LISTENER_NAMES.get(port) or "port-%d" % port

        def queue_id_decimal(queue_id):
            try:
                return str(int(str(queue_id), 16))
            except (TypeError, ValueError):
                return ""

        def build_record(payload):
            context = payload.get("context") or {}
            envelope = payload.get("envelope") or {}
            message = payload.get("message") or {}
            headers = message.get("headers") or []
            client = context.get("client") or {}
            sasl = context.get("sasl") or {}
            queue = context.get("queue") or {}
            server = context.get("server") or {}
            sender = envelope.get("from") or {}
            recipients = envelope.get("to") or []

            meta = {
                "from": clip(sender.get("address")),
                "to": clip(", ".join(str((rcpt or {}).get("address") or "") for rcpt in recipients)),
                "subject": clip(decode(header_value(headers, "subject"))),
                "messageId": clip(header_value(headers, "message-id")),
                "headerFrom": clip(decode(header_value(headers, "from"))),
                "headerTo": clip(decode(header_value(headers, "to"))),
                "queueId": clip(queue.get("id")),
                # Telemetry events emit the queue id in decimal, the hook context
                # uses hex. Emit both so the dashboard can join them.
                "queueIdDec": clip(queue_id_decimal(queue.get("id"))),
                "remoteIp": clip(client.get("ip")),
                "helo": clip(client.get("helo")),
                "authenticatedAs": clip(sasl.get("login")),
                # server.name is DAEMON_NAME ("Stalwart vX.Y.Z"), which says nothing
                # about the listener -- the accepted-on port does.
                "listenerId": clip(listener_name(server.get("port"))),
                "serverPort": clip(server.get("port")),
                "size": str(message.get("size") or 0),
            }
            # Empty values are dropped rather than sent as "": Loki would index
            # a blank structured-metadata value as a real (empty) one.
            meta = {key: value for key, value in meta.items() if value != ""}

            line = json.dumps(
                {
                    "from": meta.get("from", ""),
                    "to": meta.get("to", ""),
                    "subject": meta.get("subject", ""),
                    "size": meta.get("size", ""),
                },
                ensure_ascii=False,
            )
            return meta, line


        def push(meta, line):
            body = {
                "streams": [
                    {
                        "stream": {
                            "service_name": "stalwart",
                            "event": "mail.received",
                            "machine": "dn-cc",
                        },
                        "values": [[str(time.time_ns()), line, meta]],
                    }
                ]
            }
            request = urllib.request.Request(
                LOKI_URL,
                data=json.dumps(body).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
                response.read()


        class Handler(BaseHTTPRequestHandler):
            protocol_version = "HTTP/1.1"

            def reply(self, status, payload):
                body = json.dumps(payload).encode("utf-8")
                self.send_response(status)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def do_GET(self):
                if self.path == "/healthz":
                    return self.reply(200, {"status": "ok"})
                return self.reply(404, {"error": "not found"})

            def do_POST(self):
                if self.path != "/mta-hook":
                    return self.reply(404, {"error": "not found"})
                try:
                    length = int(self.headers.get("Content-Length") or 0)
                    payload = json.loads(self.rfile.read(length) or b"{}")
                except Exception as err:
                    print("malformed hook request: %s" % err, file=sys.stderr, flush=True)
                    return self.reply(200, {"action": "accept"})
                try:
                    meta, line = build_record(payload)
                    if meta.get("queueId") or meta.get("subject"):
                        push(meta, line)
                except Exception as err:
                    # Mail flow must not depend on Loki being reachable.
                    print("loki push failed: %s" % err, file=sys.stderr, flush=True)
                return self.reply(200, {"action": "accept"})

            def log_message(self, fmt, *args):
                return


        if __name__ == "__main__":
            server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
            print("mta hook receiver listening on 127.0.0.1:%d" % PORT, file=sys.stderr, flush=True)
            server.serve_forever()
      '';
    in
    {
      systemd.services.stalwart-mta-hook = {
        description = "Stalwart MTA hook receiver -> Loki (message subjects)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          HOOK_PORT = toString port;
          LOKI_URL = lokiUrl;
        };
        serviceConfig = {
          ExecStart = "${python3}/bin/python3 ${receiver}";
          Restart = "always";
          RestartSec = 5;
          DynamicUser = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ];
          MemoryMax = "256M";
        };
      };
    };
}
