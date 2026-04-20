{ config, ... }:
{
  imports = [
    ../../../modules/netbird-client.nix
  ];

  sops.secrets."netbird/setupKey" = {
    restartUnits = [ "netbird-wt0-login.service" ];
  };

  services.netbird.clients.wt0 = {
    ui.enable = false;
    login = {
      enable = true;
      setupKeyFile = config.sops.secrets."netbird/setupKey".path;
    };
  };
}
