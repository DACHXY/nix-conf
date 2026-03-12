{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages;
  boot.loader.systemd-boot.enable = true;
  boot.initrd.systemd.enable = true;
}
