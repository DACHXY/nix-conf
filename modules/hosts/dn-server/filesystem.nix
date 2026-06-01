{
  configurations.nixos.dn-server.module = {
    fileSystems."/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };

    fileSystems."/mnt/ssd" = {
      device = "/dev/disk/by-uuid/4E21-0000";
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

    boot.swraid.enable = true;
    boot.swraid.mdadmConf = ''
      MAILADDR smitty
      ARRAY /dev/md126 metadata=1.2 name=stuff:0
      UUID=b75dc506-8f7c-4557-8b2f-adb5f1358dbc
    '';
  };
}
