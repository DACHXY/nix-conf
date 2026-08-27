{ config, lib, ... }:
let
  inherit (config.flake.public.config) domain;

  mkIngress =
    hostname:
    let
      fqdn = if hostname != null then "${hostname}.${domain}" else domain;
    in
    {
      "${fqdn}" = {
        service = "https://127.0.0.1:443";
        originRequest = {
          originServerName = "${fqdn}";
          httpHostHeader = "${fqdn}";
        };
      };
    };
in
{
  configurations.nixos.dn-server.module = { config, lib, ... }: {
    sops.secrets."cloudflared-creds" = {
      mode = "0400";
    };

    services.cloudflared = {
      enable = true;
      tunnels = {
        "43131813-cfae-4eff-9597-f759bdc7e9e0" = {
          default = "http_status:404";
          ingress = lib.mkMerge (
            map mkIngress [
              "login"
              "nextcloud"
              "matrix"
              "matrix-auth"
              "git"
              "webmail"
              null
            ]
          );
          credentialsFile = config.sops.secrets."cloudflared-creds".path;
        };
      };
    };
  };
}
