{ config, ... }:
let
  inherit (config.flake.public.config.services) stalwart loki tempo;
in
{
  configurations.nixos.dn-server.module = {
    services.alloy.enable = true;

    # Stalwart (OtelHttp tracer) -> Alloy -> Loki (logs) + Tempo (spans), all
    # on this host. Same pipeline shape as dn-cc's alloy.nix, which forwards
    # over WireGuard instead of to loopback.
    environment.etc."alloy/stalwart.alloy".text = ''
      otelcol.receiver.otlp "stalwart" {
        http {
          endpoint = "127.0.0.1:${toString stalwart.otlpPort}"
        }

        output {
          logs   = [otelcol.processor.transform.stalwart.input]
          traces = [otelcol.processor.batch.stalwart_traces.input]
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
          endpoint = "http://127.0.0.1:${toString loki.port}/otlp"
        }
      }

      otelcol.processor.batch "stalwart_traces" {
        output {
          traces = [otelcol.exporter.otlphttp.tempo.input]
        }
      }

      otelcol.exporter.otlphttp "tempo" {
        client {
          // No path here: the exporter appends /v1/traces itself.
          endpoint = "http://127.0.0.1:${toString tempo.otlpPort}"
        }
      }
    '';
  };
}
