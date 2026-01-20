{ config, lib, ... }:
let
  inherit (config.networking) domain;

  hostname = "paperless.${domain}";
in
{
  imports = [
    (import ../../../modules/paperless-ngx.nix {
      domain = hostname;
      passwordFile = config.sops.secrets."paperless/adminPassword".path;
    })
  ];

  services.nginx.virtualHosts."${hostname}" = {
    useACMEHost = domain;
  };
}
