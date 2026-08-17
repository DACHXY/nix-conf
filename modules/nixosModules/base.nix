{ config, ... }:
{
  flake.modules.nixos.base.imports = with config.flake.modules.generic; [
    base
  ];
}
