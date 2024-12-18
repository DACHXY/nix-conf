{ config, pkgs, ... }:

{
  networking = {
    hostName = "dn-nix";
    networkmanager.enable = true;
    enableIPv6 = false;
    firewall = { 
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ 51820 ];
    };
  };
}
