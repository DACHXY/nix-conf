{ config, ... }:
{
  configurations.nixos.dn-cc.module = {
    imports = with config.flake.modules; [
      nixos.server
      nixos.danny
      nixos.danny-acme
      generic.dnywe
    ];
  };
}
