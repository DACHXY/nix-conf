{
  fqdn,
  selfMonitor ? true,
  configureNginx ? true,
  scrapes ? [ ],
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionalAttrs;
  inherit (builtins) toString;
in
{
  services.prometheus.exporters.node = mkIf selfMonitor {
    enable = true;
    port = 9000;
    enabledCollectors = [ "systemd" ];
  };

  services.prometheus = {
    enable = true;
    webExternalUrl = "https://${fqdn}";
    globalConfig = {
      scrape_interval = "10s";
    };
    scrapeConfigs = (
      [
        {
          job_name = "master-server";
          static_configs = [
            (optionalAttrs selfMonitor {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
            })
          ];
        }
      ]
      ++ scrapes
    );
  };

  services.nginx.virtualHosts."${fqdn}" = mkIf configureNginx {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
    };
  };
}
