{ config, pkgs, ... }:

{
  hardware = {
    bluetooth.enable = true;
    graphics.enable = true;
    nvidia.modesetting.enable = true;
  };
}
