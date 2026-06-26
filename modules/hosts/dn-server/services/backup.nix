{
  configurations.nixos.dn-server.module =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf;
      backupAt = "*-*-* 03:00:00";
      backupPath = "/mnt/backup_dn";
      backupScript = pkgs.writeShellScript "backup-nextcloud.sh" ''
        nextcloudPath="${config.services.nextcloud.datadir}"

        if [ ! -d "$nextcloudPath" ]; then
          echo "nextcloud path not found: $nextcloudPath"
          exit 1
        fi

        backupPath="${backupPath}"
        nextcloudBakPath="$backupPath"

        if [ ! -d "$backupPath" ]; then
          echo "Backup device is not mounted: $backupPath"
          exit 1
        fi

        echo "Start syncing..."
        ${lib.getExe pkgs.rsync} -rh --delete "$nextcloudPath" "$nextcloudBakPath"
        echo "Data dir backup completed."
      '';
    in
    {
      services.postgresqlBackup = {
        enable = true;
        startAt = backupAt;
        pgdumpOptions = "--no-owner";
        databases = [
          "nextcloud"
          "vaultwarden"
          "paperless"
          "keycloak"
          "pdns"
          "powerdnsadmin"
          "roundcube"
          "grafana"
          "crowdsec"
          "netbird"
          "forgejo"
        ];
        location = "${backupPath}/postgresql";
      };

      systemd = mkIf config.services.nextcloud.enable {
        timers = {
          "nextcloud-backup" = {
            enable = true;
            description = "Nextcloud backup";
            timerConfig = {
              OnCalendar = backupAt;
              Persistent = true;
              OnUnitActiveSec = "1d";
              AccuracySec = "1h";
              Unit = "nextcloud-backup.service";
            };
            wantedBy = [ "timers.target" ];
          };
        };

        services."nextcloud-backup" = {
          enable = true;
          script = "${backupScript}";
          serviceConfig = {
            User = "nextcloud";
          };
        };
      };
    };
}
