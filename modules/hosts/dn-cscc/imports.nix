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
      nixos.incus
      generic.dnywe
      nixos.danny-ai
      generic.ai
      nixos.punktfunk
      nixos.docker-registry
      nixos.audio-rtp
      nixos.matrix-pi-bot
    ];
  };
}
