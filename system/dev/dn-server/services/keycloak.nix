# NOTE: This is keycloak partial overwrite for `mail-server.nix`.
{ lib, config, ... }:
let
  inherit (lib) mkForce;
  inherit (config.networking) domain;
  cfg = config.services.keycloak;
in
{
  services.keycloak = {
    settings = {
      hostname = mkForce "login.${domain}";
    };
  };

  services.nginx.virtualHosts."${cfg.settings.hostname}" = {
    useACMEHost = domain;
    forceSSL = true;
    enableACME = mkForce false;
  };
}
