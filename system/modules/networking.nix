{ lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    openfortivpn
  ];

  networking = {
    networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-fortisslvpn
        networkmanager-openvpn
        networkmanager-openconnect
        networkmanager-ssh
        networkmanager-sstp
        networkmanager-l2tp
        networkmanager-vpnc
        networkmanager-strongswan
        networkmanager-iodine
      ];
    };
    enableIPv6 = lib.mkDefault false;
    firewall = {
      enable = lib.mkDefault true;
    };
  };
}
