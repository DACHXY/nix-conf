{ pkgs, lib, ... }:
let
  memeSelector = pkgs.callPackage ../../../../../home/scripts/memeSelector.nix {
    url = "https://nextcloud.net.dn/public.php/dav/files/pygHoPB5LxDZbeY/";
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
