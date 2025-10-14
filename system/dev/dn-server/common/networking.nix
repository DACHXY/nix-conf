{ lib, ... }:
with lib;
{
  networking = {
    networkmanager = {
      enable = true;
      insertNameservers = mkForce [ "127.0.0.1" ];
    };
    enableIPv6 = true;
    firewall.enable = true;
  };
}
