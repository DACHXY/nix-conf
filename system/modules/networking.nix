{ lib, ... }:
{
  networking = {
    networkmanager.enable = true;
    enableIPv6 = lib.mkDefault false;
    firewall = {
      enable = lib.mkDefault true;
    };
  };
}
