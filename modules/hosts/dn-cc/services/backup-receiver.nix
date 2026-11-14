{
  configurations.nixos.dn-cc.module =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      # dn-server's offsite public key. Until the real half of
      # /var/lib/backup-offsite/id_ed25519.pub (dn-server) is pasted here the
      # placeholder authorizes nobody: the key list stays empty.
      dnServerBackupKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkh98VrD6dACXoHgp0PF7Vn7bBTEbS6yOA1g6vQE2Aa backup@dn-server";

      # rrsync is write-only (`-wo`) and confined to the backup directory, so
      # even a compromised dn-server can only drop archives, not read or delete
      # anything else over this key.
      authorizedKeys = map (
        key:
        ''restrict,from="10.20.0.2",command="${lib.getExe pkgs.rrsync} -wo /var/backup/dn-server" ${key}''
      ) [ dnServerBackupKey ];
    in
    {
      users.groups.backup = { };

      users.users.backup = {
        isSystemUser = true;
        group = "backup";
        home = "/var/backup/dn-server";
        createHome = true;
        homeMode = "0700";
        # sshd runs the forced command through the login shell.
        shell = pkgs.bashInteractive;
        openssh.authorizedKeys.keys = lib.optionals (
          !lib.hasInfix "PLACEHOLDER" dnServerBackupKey
        ) authorizedKeys;
      };

      # Additive: modules/networking/ssh-server.nix allows the normal user and
      # this list is merged in, so danny stays.
      services.openssh.settings.AllowUsers = [ "backup" ];

      systemd.services.backup-receiver-prune = {
        description = "Delete dn-server backups older than 30 days";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.findutils}/bin/find /var/backup/dn-server -maxdepth 1 -name '*.tar.age' -type f -mtime +30 -delete";
        };
      };

      systemd.timers.backup-receiver-prune = {
        enable = true;
        description = "Delete dn-server backups older than 30 days";
        timerConfig = {
          OnCalendar = "*-*-* 04:15:00";
          Persistent = true;
          Unit = "backup-receiver-prune.service";
        };
        wantedBy = [ "timers.target" ];
      };
    };
}
