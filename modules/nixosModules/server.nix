{ config, ... }:
{
  flake.modules.nixos.server.imports = with config.flake.modules; [
    generic.server
  ];

  flake.modules.darwin.server.imports = with config.flake.modules; [
    generic.server
  ];

  flake.modules.generic.server = { };
}
