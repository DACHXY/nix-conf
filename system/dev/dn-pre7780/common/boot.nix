{
  pkgs,
  ...
}:
{
  boot.kernelPackages = pkgs.linuxPackages_6_17;

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-label/DN-SSD";
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
