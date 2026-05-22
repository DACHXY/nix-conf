{ config, ... }:
{
  flake.modules.nixos.danny = {
    imports = [ config.flake.modules.generic.danny ];
  };
}
