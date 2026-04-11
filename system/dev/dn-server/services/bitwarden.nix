{ config, ... }:
let
  inherit (config.networking) domain;
  hostname = "bitwarden.${domain}";
in
{
  imports = [
    (import ../../../modules/vaultwarden.nix {
      domain = hostname;
    })
  ];
  systemConf.security.allowedDomains = [ "icons.bitwarden.net" ];

  services.nginx.virtualHosts."${hostname}" = {
    useACMEHost = domain;
  };
}
