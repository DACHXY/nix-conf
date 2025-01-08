{ pkgs, ... }:

let
  themeConfig = {
    bgVidDay = "playlist/day.m3u";
    bgVidNight = "playlist/night.m3u";
  };
in
{
  services = {
    displayManager = {
      sddm.wayland.enable = true;
      sddm.enable = true;
      sddm.theme = "${pkgs.callPackage ./../../pkgs/sddm-themes/gruvbox.nix {
        inherit pkgs themeConfig;
      }}";
    };
  };
}
