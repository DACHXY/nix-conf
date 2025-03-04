{ config, pkgs, ... }:

{
  networking = {
    networkmanager.enable = true;
    enableIPv6 = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        20088
      ];
      allowedUDPPorts = [
        51820
        20088
      ];
    };
  };
}
