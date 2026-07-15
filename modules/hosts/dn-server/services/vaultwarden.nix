{ config, ... }:
let
  globalConfig = config;
in
{
  configurations.nixos.dn-server.module =
    { config, ... }:
    let
      cfg = config.services.vaultwarden;
      inherit (globalConfig.flake.public.config.services.vaultwarden) endpoint hostname;
      inherit (globalConfig.flake.public.config) domain;
    in
    {
      sops.secrets."vaultwarden" = { };

      services.postgresql = {
        enable = true;
        ensureUsers = [
          {
            name = "vaultwarden";
            ensureDBOwnership = true;
          }
        ];
        ensureDatabases = [
          "vaultwarden"
        ];
      };

      services.vaultwarden = {
        enable = true;
        dbBackend = "postgresql";
        environmentFile = config.sops.secrets."vaultwarden".path;
        config = {
          DOMAIN = endpoint;
          SIGNUPS_ALLOWED = false;
          SIGNUPS_VERIFY = false;
          ROCKET_PORT = 8222;
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_LOG = "critical";

          SSO_ENABLED = true;
          SSO_ONLY = true;
          SSO_SIGNUPS_MATCH_EMAIL = true;
          SSO_AUTH_ONLY_NOT_SESSION = true;

          DATABASE_URL = "postgresql:///vaultwarden";
        };
      };

      services.nginx.virtualHosts.${hostname} = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.config.ROCKET_PORT}/";
          proxyWebsockets = true;
        };
      };
    };
}
