{ config, ... }:
{
  flake.modules.nixos.server.imports = with config.flake.modules; [
    nixos.base
    generic.server
  ];

  flake.modules.generic.server = { };
}
