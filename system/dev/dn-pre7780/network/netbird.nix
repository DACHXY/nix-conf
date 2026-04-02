{ config, ... }:
let
  cfg = config.services.netbird;
in
{
  imports = [
    ../../../modules/netbird-client.nix
  ];

  sops.secrets."netbird/wt0-setupKey" = {
    owner = cfg.clients.wt0.user.name;
    mode = "400";
  };

  services.netbird.clients.wt0.login = {
    enable = true;
    setupKeyFile = config.sops.secrets."netbird/wt0-setupKey".path;
  };
}
