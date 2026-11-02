{
  flake.modules.nixos.base =
    { pkgs, lib, ... }:
    {
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    };
}
