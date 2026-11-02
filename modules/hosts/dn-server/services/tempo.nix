{ config, ... }:
let
  inherit (config.flake.public.config.machines) dn-server;
  inherit (config.flake.public.config.services) tempo;
in
{
  configurations.nixos.dn-server.module =
    { config, ... }:
    {
      # Trace backend for Stalwart's spans (Alloy on dn-cc forwards them as
      # OTLP/HTTP). Single binary, blocks on local disk, no Kafka.
      services.tempo = {
        enable = true;
        settings = {
          server = {
            # Grafana queries via loopback; dn-cc never talks to this port.
            http_listen_address = "127.0.0.1";
            http_listen_port = tempo.port;
            grpc_listen_address = "127.0.0.1";
            # Loki already owns 9095 on this host.
            grpc_listen_port = 9097;
            log_level = "warn";
          };

          # Needed for the Traces Drilldown / Explore streaming search path.
          stream_over_http_enabled = true;
          multitenancy_enabled = false;
          usage_report.reporting_enabled = false;

          distributor.receivers.otlp.protocols.http.endpoint = "0.0.0.0:${toString tempo.otlpPort}";

          storage.trace = {
            backend = "local";
            wal.path = "/var/lib/tempo/wal";
            local.path = "/var/lib/tempo/blocks";
          };

          # The module only grants StateDirectory=tempo (/var/lib/tempo), but
          # Tempo 3 defaults the live-store WAL and shutdown marker to
          # /var/tempo, which does not exist and is not writable.
          live_store = {
            wal.path = "/var/lib/tempo/live-store/wal";
            shutdown_marker_dir = "/var/lib/tempo/live-store/shutdown";
          };

          # Span metrics + service graphs stay local (no remote_write): this
          # is what the Traces Drilldown RED panels read.
          metrics_generator = {
            storage.path = "/var/lib/tempo/generator/wal";
            processor = {
              service_graphs = { };
              span_metrics = { };
            };
          };

          overrides.defaults = {
            compaction.block_retention = "720h"; # 30d, same as Loki
            metrics_generator.processors = [
              "span-metrics"
              "service-graphs"
            ];
          };
        };
      };

      # Only dn-cc (WireGuard peer on wg2) pushes spans here.
      networking.firewall.interfaces.${dn-server.wg.wg2.interface}.allowedTCPPorts = [ tempo.otlpPort ];

      services.grafana.provision.datasources.settings.datasources = [
        {
          uid = "tempo-dn-server";
          name = "Tempo";
          type = "tempo";
          url = "http://127.0.0.1:${toString tempo.port}";
          jsonData = {
            # Trace -> logs jumps land in the Stalwart history stream on Loki.
            # OTLP log records keep trace_id/span_id as structured metadata,
            # so the filter is a plain metadata match.
            tracesToLogsV2 = {
              datasourceUid = "loki-dn-server";
              spanStartTimeShift = "-5m";
              spanEndTimeShift = "5m";
              filterByTraceID = true;
              filterBySpanID = true;
              customQuery = false;
            };
            tracesToMetrics = {
              datasourceUid = "prometheus-dn-server";
            };
            nodeGraph = {
              enabled = true;
            };
            search = {
              hide = false;
            };
          };
        }
      ];
    };
}
