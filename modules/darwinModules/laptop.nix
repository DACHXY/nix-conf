{ config, ... }:
{
  flake.modules.darwin.laptop.imports = with config.flake.modules.darwin; [
    base
    gui
  ];
}
