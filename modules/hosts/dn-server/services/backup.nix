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
      fileSystems."/mnt/backup_dn" = {
        device = "/dev/disk/by-uuid/FBD9-F625";
        fsType = "exfat";
        options = [
          "x-systemd.automount"
          "noauto"
          "x-systemd.idle-timeout=600"
          "nofail"
          "user"
          "x-gvfs-show"
          "gid=1000"
          "uid=1000"
          "dmask=000"
          "fmask=000"
        ];
      };

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
