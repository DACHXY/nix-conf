# Work pretty good on ONE monitor
{
  offload ? false,
  ...
}:
{ pkgs, lib, ... }:
let
  wallpaper = "3029865244";
  assetsDir = "/mnt/windows/Users/danny/scoop/apps/steam/current/steamapps/common/wallpaper_engine/assets";
  contentDir = "/mnt/windows/Users/danny/scoop/apps/steam/current/steamapps/workshop/content/431960";
  offloadScript = import ./offload.nix { inherit pkgs; };
in
{
  imports = [ ../extra/wallpaper-engine.nix ];
  services.wallpaperEngine = {
    enable = true;
    assetsDir = assetsDir;
    contentDir = contentDir;
    extraPrefix = lib.mkIf offload "${offloadScript}/bin/offload";
    fps = 30;
    monitors = {
      "DP-3" = {
        bg = wallpaper;
      };
    };
  };
}
