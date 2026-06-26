{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services.oidc) hostname;
in
{
  configurations.nixos.dn-server.module =
    { config, ... }:
    {
      sops.secrets."oauth/password" = { };

      services.keycloak = {
        enable = true;
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
          truststore-paths = config.security.pki.caBundle;
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
