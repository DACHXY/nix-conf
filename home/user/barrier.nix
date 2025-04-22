# Use one set of mouse and keyboard to
# seamless control multiple device
{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [ barrier ];
  services.barrier.client = {
    enable = true;
    enableDragDrop = true;
    server = lib.mkDefault "192.168.0.3";
  };
}
