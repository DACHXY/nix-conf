{ config, ... }:
{
  flake.modules.darwin.base.imports = with config.flake.modules.generic; [
    base
  ];
}
