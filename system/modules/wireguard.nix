{ config, pkgs, ... }:

{
  networking.firewall = { allowedUDPPorts = [ 51820 ]; };

  networking.wg-quick.interfaces.wg0.configFile = "/etc/wireguard/wg0.conf";
}
