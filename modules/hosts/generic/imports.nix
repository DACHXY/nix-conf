{ config, ... }:
{
  configurations.nixos.generic.module = {
    imports = with config.flake.modules; [
      nixos.pc
      nixos.vpn
      generic.dnywe
    ];

    my.user.name = "generic";
  };
}
