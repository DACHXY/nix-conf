{
  configurations.nixos.dn-gcp.module =
    {
      lib,
      pkgs,
      ...
    }:
    let
      # dn-server's offsite public key — the same keypair that already pushes
      # to dn-cc (modules/hosts/dn-cc/services/backup-receiver.nix). One key,
      # two receivers: the private half never leaves dn-server.
      dnServerBackupKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkh98VrD6dACXoHgp0PF7Vn7bBTEbS6yOA1g6vQE2Aa backup@dn-server";

      # dn-server reaches this box over wg0, so the connection arrives from its
      # wg0 hub address (10.30.0.1), not from any public IP.
      authorizedKeys = map (
        key:
        ''restrict,from="10.30.0.1",command="${lib.getExe pkgs.rrsync} -wo /var/backup/dn-server" ${key}''
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

      # NOTE: `AllowUsers` is NOT set here. dn-gcp forces it in access.nix with
      # `lib.mkForce [ "danny" "root" ]` (a recovery channel), and a non-forced
      # `AllowUsers = [ "backup" ]` here would be silently overridden. The list
      # in access.nix therefore already includes "backup".

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
          # dn-server lands the archive at 03:30; give the rsync a margin.
          OnCalendar = "*-*-* 04:30:00";
          Persistent = true;
          Unit = "backup-receiver-prune.service";
        };
        wantedBy = [ "timers.target" ];
      };
    };
}
