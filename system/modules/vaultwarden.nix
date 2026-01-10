{ domain }:
{ config, ... }:
let
  inherit (config.sops) secrets;
  cfg = config.services.vaultwarden;
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
    environmentFile = secrets.vaultwarden.path;
    config = {
      DOMAIN = "https://${domain}";
      SIGNUPS_ALLOWED = true;
      SIGNUPS_VERIFY = true;
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

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString cfg.config.ROCKET_PORT}/";
      proxyWebsockets = true;
    };
  };
}
