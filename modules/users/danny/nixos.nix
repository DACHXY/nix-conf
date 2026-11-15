{ config, ... }:
{
  flake.modules.nixos.danny = {
    imports = [
      config.flake.modules.generic.danny
      config.flake.modules.nixos.server-rules
    ];
  };

  flake.modules.nixos.danny-gui = {
    imports = [ config.flake.modules.generic.danny-gui ];
  };
}
