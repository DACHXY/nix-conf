{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  fileSystems."/mnt/storage" = {
    device = "router.dn:/mnt/storage";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
    ];
  };

  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-uuid/460237D00237C429";
    fsType = "ntfs-3g";
    options = [
      "nofail"
      "uid=1000"
      "gid=1000"
      "dmask=077"
      "fmask=077"
    ];
  };

  boot.supportedFilesystems = [ "ntfs" ];
  boot.loader.systemd-boot.enable = true;

  # Enable F keys in some wireless keyboard (Ex. neo65)
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';

  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules = [
    "i915"
  ];
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = "\n  MAILADDR smitty\n  ARRAY /dev/md126 metadata=1.2 name=stuff:0\n  UUID=3b0b7c51-2681-407e-a22a-e965a8aeece7\n  ";
}
