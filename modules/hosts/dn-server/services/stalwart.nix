{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  globalConfig = config;
in
{
  configurations.nixos.dn-server.module =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [
        globalConfig.flake.modules.nixos.stalwart
      ];

      sops.secrets."stalwart/password" = {
      };

      sops.secrets."stalwart/user" = {
      };

      sops.templates."stalwart/env" = {
        content = ''
          STALWART_USER=${config.sops.placeholder."stalwart/user"}
          STALWART_PASSWORD=${config.sops.placeholder."stalwart/password"}
        '';
      };

      services.stalwart-bootstrap = {
        enable = false;
        url = "http://127.0.0.1:30094";
        credentialsFile = config.sops.templates."stalwart/env".path;
        plan = [
          {
            "@type" = "upsert";
            object = "Domain";
            matchOn = [ "name" ];
            value = {
              dom-a = {
                name = domain;
              };
            };
          }
          {
            "@type" = "update";
            object = "SystemSettings";
            value = {
              defaultDomainId = "#dom-a";
              defaultHostname = "mx.${domain}";
            };
          }
        ];
      };

      services.stalwart = {
        enable = false;
        package = pkgs.stalwart_0_16;
        stateVersion = config.system.stateVersion;
        credentials = {
          user_admin_password = config.sops.secrets."stalwart/password".path;
        };
      };
    };
}
