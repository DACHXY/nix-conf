{ config, pkgs, ... }:

{
  networking = {
    hostName = "dn-nix";
    networkmanager.enable = true;
    enableIPv6 = false;
    firewall.enable = false;
  };
}
