{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.loader.systemd-boot.enable = true;
      boot.initrd.systemd.enable = true;
    };
}
