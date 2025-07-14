{
  hostname,
  datadir ? null,
  dataBackupPath ? null,
  dbBackupPath ? null,
  https ? true,
}:
{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    "${
      fetchTarball {
        url = "https://github.com/onny/nixos-nextcloud-testumgebung/archive/fa6f062830b4bc3cedb9694c1dbf01d5fdf775ac.tar.gz";
        sha256 = "0gzd0276b8da3ykapgqks2zhsqdv4jjvbv97dsxg0hgrhb74z0fs";
      }
    }/nextcloud-extras.nix"
  ];

  services.postgresql = {
    enable = true;
    authentication = lib.mkOverride 10 ''
      #type database  DBuser  origin-address  auth-method
      local all       all                     trust
    '';
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [
      "nextcloud"
    ];
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    configureRedis = true;
    hostName = hostname;
    https = if https then true else false;
    datadir = lib.mkIf (datadir != null) datadir;
    phpExtraExtensions =
      all: with all; [
        imagick
      ];

    maxUploadSize = "10240M";

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        contacts
        calendar
        tasks
        ;

      camerarawpreviews = pkgs.fetchNextcloudApp {
        url = "https://github.com/ariselseng/camerarawpreviews/releases/download/v0.8.7/camerarawpreviews_nextcloud.tar.gz";
        sha256 = "sha256-aiMUSJQVbr3xlJkqOaE3cNhdZu3CnPEIWTNVOoG4HSo=";
        license = "agpl3Plus";
      };
    };
    extraAppsEnable = true;

    database.createLocally = true;
    config = {
      adminpassFile = config.sops.secrets."nextcloud/adminPassword".path;
      dbtype = "pgsql";
    };

    settings = {
      log_type = "file";
      enabledPreviewProviders = [
        "OC\\Preview\\BMP"
        "OC\\Preview\\GIF"
        "OC\\Preview\\JPEG"
        "OC\\Preview\\Krita"
        "OC\\Preview\\MarkDown"
        "OC\\Preview\\MP3"
        "OC\\Preview\\OpenDocument"
        "OC\\Preview\\PNG"
        "OC\\Preview\\TXT"
        "OC\\Preview\\XBitmap"
        "OC\\Preview\\HEIC"
        "OC\\Preview\\SVG"
        "OC\\Preview\\FONT"
        "OC\\Preview\\Imaginary"
        "OC\\Preview\\ImaginaryPDF"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    exiftool
  ];

  systemd = {
    timers = lib.mkIf (dataBackupPath != null || dbBackupPath != null) {
      "nextcloud-backup" = {
        enable = true;
        description = "Nextcloud backup";
        timerConfig = {
          OnCalendar = "*-*-* 03:00:00";
          Persistent = true;
          OnUnitActiveSec = "1d";
          AccuracySec = "1h";
          Unit = "nextcloud-backup.service";
        };
        wantedBy = [ "timers.target" ];
      };
    };

    services = lib.mkIf (dataBackupPath != null || dbBackupPath != null) {
      "nextcloud-backup" = {
        enable = true;
        serviceConfig = {
          User = "nextcloud";
          ExecStart =
            let
              script = pkgs.writeShellScriptBin "backup" (
                ''
                  nextcloudPath="${config.services.nextcloud.datadir}"

                  if [ ! -d "$nextcloudPath" ]; then
                    echo "nextcloud path not found: $nextcloudPath"
                    exit 1
                  fi
                ''
                + (
                  if dataBackupPath != null then
                    ''
                      backupPath="${dataBackupPath}"
                      nextcloudBakPath="$backupPath"

                      if [ ! -d "$backupPath" ]; then
                        echo "Backup device is not mounted: $backupPath"
                        exit 1
                      fi

                      echo "Start syncing..."
                      ${pkgs.rsync}/bin/rsync -rh --delete "$nextcloudPath" "$nextcloudBakPath"
                      echo "Data dir backup completed."
                    ''
                  else
                    ""
                )
                + (
                  if dbBackupPath != null then
                    ''
                      nextcloudDBBakPath="${dbBackupPath}/nextcloud-db.bak.tar"
                      if [ ! -d "$nextcloudBakPath" ]; then
                        mkdir -p "$nextcloudBakPath"
                      fi

                      echo "Try backing up database (postgresql)"
                      ${pkgs.postgresql}/bin/pg_dump -F t nextcloud -f "$nextcloudDBBakPath"
                      echo "Database backup completed."
                    ''
                  else
                    ""
                )
              );
            in
            "${script}/bin/backup";
        };
      };
    };
  };
}
