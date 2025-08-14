{ domain }:
{ config, ... }:
{
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
    environmentFile = config.sops.secrets.vaultwarden.path;
    config = {
      DOMAIN = "https://${domain}";
      SIGNUPS_ALLOWED = true;
      SIGNUPS_VERIFY = true;
      ROCKET_PORT = 8222;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_LOG = "critical";

      DATABASE_URL = "postgresql:///vaultwarden";
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass =
      "http://localhost:${toString config.services.vaultwarden.config.ROCKET_PORT}/";
  };
}
