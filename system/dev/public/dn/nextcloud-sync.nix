{
  config,
  lib,
  self,
  ...
}:
let
  inherit (builtins) length;
  inherit (lib) getExe' optionalString;
  inherit (config.systemConf) username;
  serverCfg = self.nixosConfigurations.dn-server.config;
  serverNextcloudCfg = serverCfg.services.nextcloud;
  nextcloudURL =
    (if serverNextcloudCfg.https then "https" else "http") + "://" + serverNextcloudCfg.hostName;
in
{

  home-manager.users."${username}" =
    {
      pkgs,
      config,
      ...
    }:
    let
      inherit (config.home) homeDirectory;
      pathToSync = [
        {
          target = "/Wallpapers";
          source = "${homeDirectory}/Pictures/Wallpapers";
        }
      ];
    in
    {
      sops.secrets."netrc" = {
        mode = "0700";
        sopsFile = ../sops/dn-secret.yaml;
        path = "${homeDirectory}/.netrc";
      };

      systemd.user = {
        services.nextcloud-autosync = {
          Unit = {
            Description = "Auto sync Nextcloud";
            After = "network-online.target";
          };
          Service = {
            Type = "simple";
            ExecStart = "${getExe' pkgs.nextcloud-client "nextcloudcmd"} -h -n ${
              optionalString (length pathToSync > 0) "--path"
            } ${toString (map (x: "${x.target} ${x.source}") pathToSync)} ${nextcloudURL}";
            TimeoutStopSec = "180";
            KillMode = "process";
            KillSignal = "SIGINT";
          };
          Install.WantedBy = [ "multi-user.target" ];
        };

        timers.nextcloud-autosync =
          let
            cfg = config.systemd.user.timers.nextcloud-autosync;
          in
          {
            Unit.Description = "Automatic async files with nextcloud when booted up after ${cfg.Timer.OnBootSec} then rerun every ${cfg.Timer.OnUnitActiveSec} ";
            Timer.OnBootSec = "5min";
            Timer.OnUnitActiveSec = "60min";
            Install.WantedBy = [
              "multi-user.target"
              "timers.target"
            ];
          };
        startServices = true;
      };
    };
}
