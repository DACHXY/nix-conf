{ config, pkgs, ... }:

{
  networking = {
    networkmanager.enable = true;
    enableIPv6 = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        443
        80
        30072
      ];
      allowedUDPPorts = [
        51820
      ];
    };
  };
}
