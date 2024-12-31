{ config, pkgs, ... }:
let
  configPath = "/etc/wireguard/wg0.conf";
in
{
  networking.firewall = { allowedUDPPorts = [ 51820 ]; };
  networking.wg-quick.interfaces.wg0.configFile = configPath;
}
