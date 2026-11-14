{ config, ... }:
let
  # The flake's own config (host IPs live in modules/config/public-config.nix),
  # as opposed to the NixOS `config` inside the module below.
  globalConfig = config;
in
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

      # The exFAT disk that holds the nightly dumps has no permissions at all
      # (mode 777 everywhere) and there is no offsite copy. Everything that
      # leaves the internal disk is age-encrypted to these three keys first, so
      # the disk -- and dn-cc -- only ever see ciphertext. No private key lives
      # on the server.
      ageRecipients = [
        "age1uc7rnxprh7372xrsmvg9qjgztd4tgrznymnw85ndkkvqtfmm24cqrme4er"
        "age1re6fndpj0hntw3hp04wv48s0947lgxw5w2y9jmxazx763ux8qggs045u2n"
        "age1zjr036sqst5spej96gvc279ql4cjmx78e3mk8cwgz9mylw60pdtq04c2h0"
      ];
      offsiteIp = globalConfig.flake.public.config.machines.dn-cc.ip;
      encryptedDir = "/var/backup/encrypted";
      offsiteDir = "/var/lib/backup-offsite";

      # Generates the offsite keypair on first run; the public half has to be
      # pasted into modules/hosts/dn-cc/services/backup-receiver.nix.
      offsiteKeyScript = pkgs.writeShellApplication {
        name = "backup-offsite-key";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.openssh
        ];
        text = ''
          dir=${offsiteDir}
          if [ ! -f "$dir/id_ed25519" ]; then
            ssh-keygen -q -t ed25519 -N "" -C backup@dn-server -f "$dir/id_ed25519"
          fi
          [ -f "$dir/known_hosts" ] || : > "$dir/known_hosts"
          chmod 0600 "$dir/known_hosts"
        '';
      };

      encryptedBackupScript = pkgs.writeShellApplication {
        name = "backup-encrypted";
        runtimeInputs = [
          pkgs.age
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnutar
          pkgs.gzip
          pkgs.rsync
          pkgs.openssh
          pkgs.util-linux
        ];
        text = ''
          postgresDir=${config.services.postgresqlBackup.location}
          # The vaultwarden module has no dataDir option; this is its StateDirectory.
          vaultwardenDir=/var/lib/vaultwarden
          outDir=${encryptedDir}
          offsiteDir=${offsiteDir}
          name="dn-server-$(date +%F).tar.age"

          if [ ! -d "$postgresDir" ]; then
            echo "no database dumps in $postgresDir" >&2
            exit 1
          fi
          if [ ! -d "$vaultwardenDir" ]; then
            echo "no vaultwarden data in $vaultwardenDir" >&2
            exit 1
          fi

          install -d -m 0700 "$outDir"
          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT

          # tar | age in one pipeline: the plaintext archive never reaches a disk.
          # The .prev rotation copies of the dumps and vaultwarden's caches are
          # regenerable, so they are left out.
          tar -cz -f - \
            --exclude='*.prev.*' \
            --exclude='vaultwarden/icon_cache' \
            --exclude='vaultwarden/tmp' \
            -C "$(dirname "$postgresDir")" "$(basename "$postgresDir")" \
            -C "$(dirname "$vaultwardenDir")" "$(basename "$vaultwardenDir")" \
            | age ${lib.concatMapStrings (recipient: "-r ${recipient} ") ageRecipients}\
            > "$tmp/$name"

          mv "$tmp/$name" "$outDir/$name"

          if mountpoint -q ${backupPath}; then
            install -d -m 0700 ${backupPath}/encrypted
            cp "$outDir/$name" ${backupPath}/encrypted/
            find ${backupPath}/encrypted -maxdepth 1 -name '*.tar.age' -type f -mtime +14 -delete
          else
            echo "warning: ${backupPath} is not mounted, skipping the disk copy" >&2
          fi

          # The newest 14 archives stay on the internal disk, the one just written
          # included; anything past that is about a fortnight of dailies.
          find "$outDir" -maxdepth 1 -name '*.tar.age' -type f -printf '%T@ %p\n' \
            | sort -rn \
            | tail -n +15 \
            | cut -d' ' -f2- \
            | xargs -r rm -f

          # Offsite last: a failure here fails the unit, after the local copies
          # above are in place. dn-cc runs rrsync, so this can only write.
          rsync -e "ssh -i $offsiteDir/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$offsiteDir/known_hosts" \
            -- "$outDir/$name" "backup@${offsiteIp}:"
        '';
      };
    in
    lib.mkMerge [
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
          # Root/postgres-only, on the internal disk: the dumps are plaintext,
          # so they must not sit on a world-readable exFAT volume.
          location = "/var/backup/postgresql";
        };

        systemd = {
          tmpfiles.rules = [
            "d ${encryptedDir} 0700 root root -"
          ];

          services.backup-encrypted = {
            description = "Encrypted backup of the PostgreSQL dumps and Vaultwarden";
            serviceConfig = {
              Type = "oneshot";
              StateDirectory = "backup-offsite";
              StateDirectoryMode = "0700";
              ExecStartPre = lib.getExe offsiteKeyScript;
              ExecStart = lib.getExe encryptedBackupScript;
              # Writable: the archive directory, the exFAT disk and the state
              # directory (offsite key). The dumps and the Vaultwarden data are
              # only read.
              ReadWritePaths = [
                encryptedDir
                backupPath
              ];
              ProtectSystem = "strict";
              ProtectHome = true;
              PrivateTmp = true;
              NoNewPrivileges = true;
              RestrictSUIDSGID = true;
              RestrictAddressFamilies = [
                "AF_UNIX"
                "AF_INET"
                "AF_INET6"
                "AF_NETLINK"
              ];
            };
          };

          timers.backup-encrypted = {
            enable = true;
            description = "Encrypted backup of the PostgreSQL dumps and Vaultwarden";
            timerConfig = {
              # Half an hour after postgresqlBackup dumps the databases.
              OnCalendar = "*-*-* 03:30:00";
              Persistent = true;
              Unit = "backup-encrypted.service";
            };
            wantedBy = [ "timers.target" ];
          };
        };
      }

      (mkIf config.services.nextcloud.enable {
        systemd.timers."nextcloud-backup" = {
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

        systemd.services."nextcloud-backup" = {
          enable = true;
          script = "${backupScript}";
          serviceConfig = {
            User = "nextcloud";
          };
        };
      })
    ];
}
