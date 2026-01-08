# NOTE: This is keycloak partial overwrite for `mail-server.nix`.
{ lib, config, ... }:
let
  inherit (lib) mkForce;
  domain = "dnywe.com";
  cfg = config.services.keycloak;
in
{
  services.keycloak = {
    settings = {
      hostname = mkForce "login.${domain}";
    };
  };

  # Disable nginx reverse proxy
  services.nginx.virtualHosts."${cfg.settings.hostname}" = mkForce { };
}
