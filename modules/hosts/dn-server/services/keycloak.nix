{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services) nextcloud;
  inherit (config.flake.public.config.services.oidc) hostname;
in
{
  configurations.nixos.dn-server.module =
    { config, ... }:
    let
      keycloakTheme = builtins.fetchurl {
        url = "${nextcloud.endpoint}/s/CQeeFf6BiSztTci/download";
        sha256 = "sha256:01i12k81hvws835gv27c1dhidxljl011ih4rh6cjpn6cayvd2nhy";
        name = "keycloak-theme-kc26.jar";
      };
    in
    {
      sops.secrets."oauth/password" = { };

      services.keycloak = {
        enable = true;
        plugins = [
          keycloakTheme
        ];

        database = {
          type = "postgresql";
          name = "keycloak";
          createLocally = true;
          passwordFile = config.sops.secrets."oauth/password".path;
        };

        settings = {
          inherit hostname;
          proxy-headers = "xforwarded";
          http-port = 38080;
          http-enabled = true;
          health-enabled = true;
          http-management-port = 38081;
        };
      };

      services.nginx.virtualHosts."${hostname}" = {
        useACMEHost = domain;
        forceSSL = true;
        locations."/".proxyPass =
          "http://127.0.0.1:${toString config.services.keycloak.settings.http-port}";
        locations."/health".proxyPass =
          "http://127.0.0.1:${toString config.services.keycloak.settings.http-management-port}/health";
      };
    };
}
