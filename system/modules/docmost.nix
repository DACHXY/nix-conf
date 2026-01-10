{
  fqdn ? null,
  port ? 32000,
  https ? true,
  openFirewall ? false,
  extraConf ? { },
  envFile ? null,
}:
{
  lib,
  config,
  ...
}:
let
  inherit (lib) optionalString mkIf;
in
{
  networking.firewall.allowedTCPPorts = mkIf openFirewall [
    port
  ];

  services.redis.servers."docmost" = {
    enable = true;
    port = 32001;
  };

  services.postgresql = {
    ensureDatabases = [ "docmost" ];
    ensureUsers = [
      {
        name = "docmost";
        ensureDBOwnership = true;
      }
    ];
  };

  virtualisation.oci-containers = {
    backend = lib.mkDefault "docker";
    containers = {
      docmost = {
        image = "docmost/docmost:latest";
        environment = (
          {
            PORT = "${toString port}";
            APP_URL = "${
              if (fqdn != null) then
                "${if https then "https" else "http"}://${fqdn}"
              else
                "http://127.0.0.1:${toString port}"
            }";
            DATABASE_URL = "postgresql://docmost@docmost?schema=public&host=/var/run/postgresql";
            REDIS_URL = "redis://127.0.0.1:${toString config.services.redis.servers.docmost.port}";
          }
          // extraConf
        );
        extraOptions = [
          "--network=host"
          "${optionalString (envFile != null) "--env-file=${envFile}"}"
        ];
        volumes = [
          "/var/run/postgresql:/var/run/postgresql"
          "docmost:/app/data/storage"
        ];
      };
    };
  };

  services.nginx = {
    enable = lib.mkDefault true;
    enableReload = lib.mkDefault true;
    recommendedGzipSettings = lib.mkDefault true;
    recommendedOptimisation = lib.mkDefault true;
    recommendedTlsSettings = lib.mkDefault true;
    recommendedProxySettings = lib.mkDefault true;
    virtualHosts = lib.mkIf (fqdn != null) {
      "${fqdn}" = {
        enableACME = lib.mkIf https true;
        forceSSL = lib.mkIf https true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
