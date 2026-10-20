{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.machines) dn-cc;
  inherit (config.flake.public.config.services.prometheus) hostname endpoint;
  inherit (config.flake.public.config.services.stalwart) metricsPort;
in
{
  configurations.nixos.dn-server.module =
    { config, lib, ... }:
    let
      inherit (lib) optional;
      inherit (config.networking) hostName;
    in
    {
      services.prometheus.exporters.node = {
        enable = true;
        port = 9000;
        enabledCollectors = [ "systemd" ];
      };

      services.prometheus = {
        enable = true;
        webExternalUrl = endpoint;
        globalConfig = {
          scrape_interval = "10s";
        };

        scrapeConfigs = [
          {
            job_name = "master-server";
            static_configs = [
              {
                targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
              }
            ];
          }
        ]
        ++ (optional config.services.pdns-recursor.enable {
          job_name = "powerdns_recursor";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.pdns-recursor.api.port}" ];
              labels = {
                machine = "${hostName}";
              };
            }
          ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "instance";
              regex = "(.*):[0-9]+";
              replacement = "PDNS Recursor - \${1}";
            }
          ];
        })
        ++ (optional
          (config.services.crowdsec.enable && config.services.crowdsec.settings.general.prometheus.enabled)
          {
            job_name = "crowdsec";
            static_configs = [
              {
                targets = [
                  "127.0.0.1:${toString config.services.crowdsec.settings.general.prometheus.listen_port}"
                ];
                labels = {
                  machine = "${hostName}";
                };
              }
            ];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "instance";
                regex = "(.*):[0-9]+";
                replacement = "CrowdSec - \${1}";
              }
            ];

          }
        )
        ++ (optional config.services.netbird.server.management.enable {
          job_name = "netbird";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString config.services.netbird.server.management.metricsPort}"
              ];
              labels = {
                machine = "${hostName}";
              };
            }
          ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "instance";
              regex = "(.*):[0-9]+";
              replacement = "Netbird - \${1}";
            }
          ];
        })
        ++ [
          {
            # One job, two hosts: both run the same Stalwart build, so the
            # metric names are identical and a panel can either aggregate them
            # (`sum(...)`) or split them (`sum by (machine) (...)`). The
            # `machine` label is the switch; `instance` has to differ or the
            # legends would collide.
            job_name = "stalwart";
            metrics_path = "/metrics/prometheus";
            static_configs = [
              {
                targets = [ "${dn-cc.ip}:${toString metricsPort}" ];
                labels = {
                  machine = "dn-cc";
                  instance = "Stalwart (dn-cc) - ${dn-cc.ip}";
                };
              }
              {
                # dn-server's own Stalwart serves the same endpoint on its
                # loopback management listener (services/stalwart.nix:21).
                targets = [ "127.0.0.1:30093" ];
                labels = {
                  machine = "dn-server";
                  instance = "Stalwart (dn-server) - 127.0.0.1";
                };
              }
            ];
          }
        ];
      };

      services.nginx.virtualHosts."${hostname}" = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
        };
      };
    };

}
