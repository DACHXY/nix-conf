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
    hostName = "nextcloud.net.dn";
    https = true;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        news
        contacts
        calendar
        tasks
        ;

      memories = pkgs.fetchNextcloudApp {
        sha256 = "sha256-BfxJDCGsiRJrZWkNJSQF3rSFm/G3zzQn7C6DCETSzw4=";
        url = "https://github.com/pulsejet/memories/releases/download/v7.5.2/memories.tar.gz";
        license = "agpl3Plus";
      };

      passwords =
        (pkgs.fetchNextcloudApp {
          sha256 = "sha256-Nu6WViFawQWby9CEEezAwoBNdp7O5O8a9IhDp/me/E0=";
          url = "https://git.mdns.eu/api/v4/projects/45/packages/generic/passwords/2025.2.0/passwords.tar.gz";
          license = "agpl3Plus";
        }).overrideAttrs
          (prev: {
            unpackPhase = ''
              cp $src passwords.tar.gz
              tar -xf passwords.tar.gz
              mv passwords/* ./
              rm passwords.tar.gz
              rm -r passwords
            '';
          });
    };
    extraAppsEnable = true;

    database.createLocally = true;
    config = {
      adminpassFile = config.sops.secrets."nextcloud/adminPassword".path;
      dbtype = "pgsql";
    };

    settings = {
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
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    exiftool
  ];

  systemd.timers."nextcloud-backup" = {
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

  systemd.services."nextcloud-backup" = {
    enable = true;
    serviceConfig = {
      User = "nextcloud";
      ExecStart =
        let
          script = pkgs.writeShellScriptBin "backup" ''
            nextcloudPath="/var/lib/nextcloud"
            mountPoint="/mnt/backup_dn"
            nextcloudBakPath="$mountPoint"
            nextcloudDBBakPath="$mountPoint/nextcloud-db.bak.tar"

            if [ ! -d "$nextcloudPath" ]; then
              echo "nextcloud path not found: $nextcloudPath"
              exit 1
            fi

            if [ ! -d "$mountPoint" ]; then
              echo "Backup device is not mounted: $mountPoint"
              exit 1
            fi

            if [ ! -d "$nextcloudBakPath" ]; then
              mkdir -p "$nextcloudBakPath"
            fi

            echo "Start syncing..."
            ${pkgs.rsync}/bin/rsync -rh --delete "$nextcloudPath" "$nextcloudBakPath"
            echo "Data dir backup completed."

            echo "Try backing up database (postgresql)"
            ${pkgs.postgresql}/bin/pg_dump -F t nextcloud -f "$nextcloudDBBakPath"
            echo "Database backup completed."
          '';
        in
        "${script}/bin/backup";
    };
  };
}
