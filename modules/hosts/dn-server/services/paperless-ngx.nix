{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services.paperless) hostname endpoint;
in
{
  configurations.nixos.dn-server.module =
    { config, pkgs, ... }:
    {
      sops.secrets = {
        "paperless/adminPassword" = {
          owner = config.services.paperless.user;
        };
      };

      services.paperless = {
        enable = true;
        passwordFile = config.sops.secrets."paperless/adminPassword".path;
        consumptionDirIsPublic = true;
        domain = hostname;
        package = pkgs.paperless-ngx;
        settings = {
          PAPERLESS_CONSUMER_IGNORE_PATTERN = [
            ".DS_STORE/*"
            "desktop.ini"
          ];
          PAPERLESS_OCR_USER_ARGS = {
            optimize = 1;
            pdfa_image_compression = "lossless";
          };
          PAPERLESS_URL = endpoint;
        };
        configureTika = false;
        database.createLocally = true;
      };

      services.nginx.virtualHosts."${hostname}" = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.paperless.port}";
      };
    };
}
