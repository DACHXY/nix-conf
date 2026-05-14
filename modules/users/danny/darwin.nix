{ config, ... }:
{
  flake.modules.darwin.danny.imports = [ config.flake.modules.generic.danny ];
}
