{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services.uptime) hostname;
in
{
  configurations.nixos.dn-server.module = {
    virtualisation.oci-containers.containers = {
      uptime-kuma = {
        extraOptions = [ "--network=host" ];
        image = "louislam/uptime-kuma:2";
        volumes = [
          "/var/lib/uptime-kuma:/app/data"
        ];
      };
    };

    services.nginx.virtualHosts."${hostname}" = {
      useACMEHost = domain;
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:3001";
    };
  };
}
