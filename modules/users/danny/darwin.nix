{ config, ... }:
{
  flake.modules.darwin.danny.imports = [ config.flake.modules.generic.danny ];
  flake.modules.darwin.danny-gui.imports = [ config.flake.modules.generic.danny-gui ];
}
