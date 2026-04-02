{
  self,
  pkgs,
  lib,
  ...
}:
let
  serverCfg = self.nixosConfigurations.dn-server.config;
  inherit (serverCfg.services.nextcloud) hostName;
  memeSelector = pkgs.callPackage ../../../../../home/scripts/memeSelector.nix {
    url = "https://${hostName}/public.php/dav/files/pygHoPB5LxDZbeY/";
  };
in
{
  home.packages = [
    memeSelector
  ];

  wayland.windowManager.hyprland = {
    settings = {
      debug.disable_logs = lib.mkForce false;
      misc = {
        vrr = 0;
      };
      bind = [
        "$mainMod ctrl, M, exec, ${memeSelector}/bin/memeSelector"
      ];
    };
  };
}
