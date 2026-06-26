{ config, ... }:
{
  flake.modules.nixos.danny = {
    imports = [ config.flake.modules.generic.danny ];
  };

  flake.modules.nixos.danny-gui = {
    imports = [ config.flake.modules.generic.danny-gui ];
  };
}
