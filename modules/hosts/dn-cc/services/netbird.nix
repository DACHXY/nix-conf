{ config, ... }:
let
  globalConfig = config;
in
{
  configurations.nixos.dn-cc.module =
    {
      config,
      lib,
      ...
    }:
    {
      imports = with globalConfig.flake.modules.nixos; [
        vpn
      ];

      sops.secrets."netbird/setupKey" = {
        restartUnits = [ "netbird-wt0-login.service" ];
      };

      services.netbird.clients.wt0 = {
        ui.enable = lib.mkForce false;
        login = {
          enable = true;
          setupKeyFile = config.sops.secrets."netbird/setupKey".path;
        };
      };

      systemd.services.netbird-wt0.after = [ "nginx.service" ];
    };
}
