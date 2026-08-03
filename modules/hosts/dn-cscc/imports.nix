{ config, ... }:
{
  configurations.nixos.dn-cscc.module = {
    imports = with config.flake.modules; [
      nixos.pc
      nixos.vpn
      nixos.danny
      nixos.danny-gui
      nixos.nvf
      nixos.gaming
      nixos.virtualisation
      generic.dnywe
      nixos.danny-claude
      generic.claude
    ];
  };
}
