{ config, ... }:
let
  inherit (config.flake.public.config.machines) dn-server;
  inherit (config.flake.public.config.services.loki) port;
in
{
  configurations.nixos.dn-server.module =
    { config, ... }:
    let
      dataDir = config.services.loki.dataDir;
    in
    {
      services.loki = {
        enable = true;
        configuration = {
          auth_enabled = false;
          analytics.reporting_enabled = false;

          server = {
            # dn-cc pushes OTLP over WireGuard; Grafana queries via loopback.
            http_listen_address = "0.0.0.0";
            http_listen_port = port;
            grpc_listen_address = "127.0.0.1";
            grpc_listen_port = 9095;
          };

          common = {
            path_prefix = dataDir;
            replication_factor = 1;
            # gRPC only listens on loopback, so every component (rings and the
            # query frontend) must advertise loopback too, or queries hang
            # dialing the host's interface address.
            instance_addr = "127.0.0.1";
            ring.kvstore.store = "inmemory";
            storage.filesystem = {
              chunks_directory = "${dataDir}/chunks";
              rules_directory = "${dataDir}/rules";
            };
          };

          schema_config.configs = [
            {
              from = "2026-10-01";
              store = "tsdb";
              object_store = "filesystem";
              # v13 + tsdb is required for structured metadata, which is where
              # OTLP log attributes (from, to, remoteIp, event, ...) end up.
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];

          limits_config = {
            allow_structured_metadata = true;
            retention_period = "720h"; # 30d
            # Top-N panels group by remoteIp / sender.
            max_query_series = 5000;
          };

          compactor = {
            working_directory = "${dataDir}/compactor";
            retention_enabled = true;
            delete_request_store = "filesystem";
          };
        };
      };

      # Only dn-cc (WireGuard peer on wg2) pushes logs here.
      networking.firewall.interfaces.${dn-server.wg.wg2.interface}.allowedTCPPorts = [ port ];

      services.grafana.provision.datasources.settings.datasources = [
        {
          uid = "loki-dn-server";
          name = "Loki";
          type = "loki";
          url = "http://127.0.0.1:${toString port}";
        }
      ];
    };
}
