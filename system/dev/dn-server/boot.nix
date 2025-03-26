{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages;

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
  boot.swraid.mdadmConf = ''
    MAILADDR smitty
    ARRAY /dev/md126 metadata=1.2 name=stuff:0
    UUID=b75dc506-8f7c-4557-8b2f-adb5f1358dbc
  '';
}
