{ pkgs, ... }:
let
  memeSelector = pkgs.callPackage ../../../home/scripts/memeSelector.nix {
    url = "https://nextcloud.net.dn/public.php/dav/files/pygHoPB5LxDZbeY/";
  };
in
{
  home.packages = [
    memeSelector
  ];

  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        ''desc:ASUSTek COMPUTER INC ASUS VG32VQ1B 0x00002271, 2560x1440@165, 0x0, 1''
        ''desc:Acer Technologies XV272U V3 1322131231233, 2560x1440@180, -1440x-600, 1, transform, 1''
      ];
      misc = {
        vrr = 0;
      };
      bind = [
        "$mainMod ctrl, M, exec, ${memeSelector}/bin/memeSelector"
      ];
    };
  };
}
