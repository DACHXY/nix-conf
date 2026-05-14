{ config, ... }:
{
  flake.modules.nixos.danny =
    { ... }@nixosArgs:
    {
      home-manager.users.${nixosArgs.config.my.user.name} =
        { lib, pkgs, ... }@hmArgs:

        let
          inherit (lib)
            getExe'
            mkMerge
            mapAttrsToList
            ;
          inherit (hmArgs.config.home) homeDirectory;
          nextcloudURL = config.flake.public.config.services.nextcloud.endpoint;

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
                cfg = hmArgs.config.systemd.user.timers."nextcloud-autosync-${name}";
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
            sopsFile = ./secret.yaml;
            path = "${homeDirectory}/.netrc";
          };

          systemd.user = mkMerge (
            mapAttrsToList (name: value: mkSyncSystemd name value.target value.source) pathToSync
          );
        };
    };
}
