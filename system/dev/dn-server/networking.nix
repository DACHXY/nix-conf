{ lib, ... }:
with lib;
{
  networking = {
    domain = "net.dn";
    networkmanager = {
      enable = true;
      insertNameservers = mkForce [ "127.0.0.1" ];
    };
    enableIPv6 = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        443
        80
      ];
    };
  };
}
