{ config, ... }:
{
  flake.modules.nixos.danny =
    { ... }@nixosArgs:
    {
      # Decrypted by the system sops-nix (root-only host key), owned by the user.
      sops.secrets."netrc" = {
        sopsFile = ./secret.yaml;
        owner = nixosArgs.config.my.user.name;
        mode = "0400";
        path = "${nixosArgs.config.users.users.${nixosArgs.config.my.user.name}.home}/.netrc";
      };

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
            csit = {
              target = "/CSIT";
              source = "${homeDirectory}/Documents/CSIT";
            };
          };
          # =============================== #

          mkSyncSystemd =
            name:
            {
              target,
              source,
              interval ? "60min",
            }:
            {
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
                  Timer.OnUnitActiveSec = interval;
                  Install.WantedBy = [
                    "multi-user.target"
                    "timers.target"
                  ];
                };
              startServices = true;

              tmpfiles.rules = [ "d ${source} 0750 - - -" ];
            };
        in
        {
          systemd.user = mkMerge (mapAttrsToList mkSyncSystemd pathToSync);
        };
    };
}
