{
  assetsPath ? null,
  fps ? 30,
  # example: [
  # { monitor = "HDMI-A1"; id = "12938798"; }
  # ]
  monitorIdPairs ? [ ],
}:
{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib) mkForce mkIf;
  defaultSettings = {
    inherit fps;
    audio = {
      silent = true;
      processing = true;
    };
    scaling = "default";
  };

  defaultAssetsPath = ''""'';
  finalAssetsPath = if assetsPath == null then defaultAssetsPath else assetsPath;
  cfg = config.services.linux-wallpaperengine;
in
{
  services.swww.enable = mkForce false;

  services.linux-wallpaperengine = {
    enable = true;
    wallpapers = map (
      pair:
      {
        wallpaperId = toString pair.id;
        monitor = pair.monitor;
      }
      // defaultSettings
    ) monitorIdPairs;
  };

  systemd.user.services."linux-wallpaperengine" =
    let
      args = lib.lists.forEach cfg.wallpapers (
        each:
        lib.concatStringsSep " " (
          lib.cli.toGNUCommandLine { } {
            screen-root = each.monitor;
            inherit (each) scaling;
            noautomute = !each.audio.automute;
            no-audio-processing = !each.audio.processing;
          }
          ++ each.extraOptions
        )
        # This has to be the last argument in each group
        + " --bg ${each.wallpaperId}"
      );
    in
    {
      Service = {
        ExecStart = mkForce (toString [
          (lib.getExe cfg.package)
          "--fps ${toString fps}"
          "--silent"
          "--assets-dir ${finalAssetsPath}"
          (lib.strings.concatStringsSep " " args)
        ]);
        Environment = mkIf osConfig.hardware.nvidia.prime.offload.enableOffloadCmd [
          "__NV_PRIME_RENDER_OFFLOAD=1"
          "__NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0"
          "__GLX_VENDOR_LIBRARY_NAME=nvidia"
          "__VK_LAYER_NV_optimus=NVIDIA_only"
        ];
      };
    };
}
