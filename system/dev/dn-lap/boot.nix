{ ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';

  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules = [ "i915" ];
  boot.swraid.enable = true;
}
