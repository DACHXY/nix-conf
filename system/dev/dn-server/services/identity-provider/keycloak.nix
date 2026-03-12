{ config, ... }:
let
  inherit (config.networking) domain;
  inherit (config.sops) secrets;
  hostname = "login";
  cfg = config.services.keycloak;
in
{
  sops.secrets = {
    "oauth/password" = { };
  };

  # ==== Keycloak Service ==== #
  systemd.services.keycloak = {
    owner = "keycloak";
    group = "keycloak";
    mode = "440"; # Read Only
  };

  # ==== Keycloak Service ==== #
  services.keycloak = {
    enable = true;

    database = {
      type = "postgresql";
      name = "keycloak";
      createLocally = true;
      passwordFile = secrets."oauth/password".path;
    };

    settings = {
      hostname = "${hostname}.${domain}";
      proxy-headers = "xforwarded";
      http-port = 38080;
      http-enabled = true;
      health-enabled = true;
      http-management-port = 38081;
    };
  };

  services.nginx.virtualHosts."${cfg.settings.hostname}" = {
    useACMEHost = domain;
    forceSSL = true;

    locations."/".proxyPass = "http://127.0.0.1:${toString cfg.settings.http-port}";
    locations."/health".proxyPass =
      "http://127.0.0.1:${toString cfg.settings.http-management-port}/health";
  };
}
