# Work pretty good on ONE monitor
{
  config,
  ...
}:
{ lib, ... }:
let
  wallpaper = "3029865244";
  assetsDir = "/mnt/windows/Users/danny/scoop/apps/steam/current/steamapps/common/wallpaper_engine/assets";
  contentDir = "/mnt/windows/Users/danny/scoop/apps/steam/current/steamapps/workshop/content/431960";
in
{
  imports = [ ../extra/wallpaper-engine.nix ];
  services.wallpaperEngine = {
    enable = true;
    assetsDir = assetsDir;
    contentDir = contentDir;
    extraPrefix = lib.mkIf config.hardware.nvidia.prime.offload.enableOffloadCmd "nvidia-offload";
    fps = 30;
    monitors = {
      "DP-3" = {
        bg = wallpaper;
      };
    };
  };
}
