{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib)
    getExe'
    mkMerge
    mapAttrsToList
    ;
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

      # ==== Add path to sync here ==== #
      pathToSync = {
        wallpapers = {
          target = "/Wallpapers";
          source = "${homeDirectory}/Pictures/Wallpapers";
        };
        notes = {
          target = "/Notes";
          source = "${homeDirectory}/notes";
        };
      };

      mkSyncSystemd = name: target: source: {
        services."nextcloud-autosync-${name}" = {
          Unit = {
            Description = "Auto sync Nextcloud";
            After = "network-online.target";
          };
          Service = {
            Type = "simple";
            ExecStart = "${getExe' pkgs.nextcloud-client "nextcloudcmd"} -h -n --path ${target} ${source} ${nextcloudURL}";
            TimeoutStopSec = "180";
            KillMode = "process";
            KillSignal = "SIGINT";
          };
          Install.WantedBy = [ "multi-user.target" ];
        };

        timers."nextcloud-autosync-${name}" =
          let
            cfg = config.systemd.user.timers."nextcloud-autosync-${name}";
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
    in
    {
      sops.secrets."netrc" = {
        mode = "0700";
        sopsFile = ../sops/dn-secret.yaml;
        path = "${homeDirectory}/.netrc";
      };

      systemd.user = mkMerge (
        mapAttrsToList (name: value: mkSyncSystemd name value.target value.source) pathToSync
      );
    };
}
