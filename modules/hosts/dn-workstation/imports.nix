{ config, ... }:
{
  configurations.nixos.dn-workstation.module = {
    imports = with config.flake.modules; [
      nixos.pc
      nixos.vpn
      nixos.danny
      nixos.nvf
      nixos.secure-boot
      generic.dnywe
    ];
  };
}
