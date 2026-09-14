{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services) aria;
in
{
  configurations.nixos.dn-workstation.module =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [ motrix-next ];

      services.nginx.virtualHosts."${aria.hostname}" = {
        useACMEHost = domain;
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:29100";
      };
    };
}
