{ config, ... }:
{
  configurations.nixos.dn-cscc.module = {
    imports = with config.flake.modules; [
      nixos.pc
      nixos.vpn
      nixos.danny
      nixos.nvf
      generic.dnywe
    ];
  };
}
