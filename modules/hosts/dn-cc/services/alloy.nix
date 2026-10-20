{ config, ... }:
let
  inherit (config.flake.public.config.machines) dn-server;
  inherit (config.flake.public.config.services) stalwart loki;
in
{
  configurations.nixos.dn-cc.module = {
    services.alloy.enable = true;

    # Stalwart (OtelHttp tracer) -> Alloy -> Loki on dn-server over WireGuard.
    environment.etc."alloy/stalwart.alloy".text = ''
      otelcol.receiver.otlp "stalwart" {
        http {
          endpoint = "127.0.0.1:${toString stalwart.otlpPort}"
        }

        output {
          logs = [otelcol.processor.transform.stalwart.input]
        }
      }

      // Loki's OTLP ingest drops LogRecord.EventName, which is the only
      // place Stalwart puts the stable event id (e.g. queue.message-queued);
      // the body is just a human-readable description. Keep it as an
      // attribute so it lands in Loki's structured metadata as `event`.
      otelcol.processor.transform "stalwart" {
        error_mode = "ignore"

        log_statements {
          context    = "log"
          statements = [
            `set(attributes["event"], event_name) where event_name != ""`,
          ]
        }

        output {
          logs = [otelcol.processor.batch.stalwart.input]
        }
      }

      otelcol.processor.batch "stalwart" {
        output {
          logs = [otelcol.exporter.otlphttp.loki.input]
        }
      }

      otelcol.exporter.otlphttp "loki" {
        client {
          // The exporter appends /v1/logs.
          endpoint = "http://${dn-server.ip}:${toString loki.port}/otlp"
        }
      }
    '';
  };
}
