{ ... }:

{

  fileSystems."/mnt/storage" = {
    device = "router.dn:/mnt/storage";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
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
