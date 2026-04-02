{ config, ... }:
let
  listenPort = 51820;
  ipPrefix = "10.20.0";
  wgInterface = "wg0";
  externalInterface = "ens192";
in
{
  sops.secrets."wireguard/privateKey" = {
    mode = "640";
    owner = "systemd-network";
    group = "systemd-network";
  };

  networking.firewall.allowedUDPPorts = [ listenPort ];

  networking.nat = {
    enable = true;
    enableIPv6 = true;
    externalInterface = externalInterface;
    internalInterfaces = [ wgInterface ];
  };

  systemd.network = {
    enable = true;

    networks."50-${wgInterface}" = {
      networkConfig = {
        DNS = [ "10.20.0.2" ];
        Domains = [ "~dnywe.com" ];
        IPv4Forwarding = true;
        IPv6Forwarding = true;
      };

      matchConfig.Name = "${wgInterface}";
      address = [
        "${ipPrefix}.1/32"
      ];
    };

    netdevs."50-${wgInterface}" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "${wgInterface}";
      };

      wireguardConfig = {
        ListenPort = listenPort;
        PrivateKeyFile = config.sops.secrets."wireguard/privateKey".path;
        RouteTable = "main";
        FirewallMark = 42;
      };

      wireguardPeers = [
        {
          # dn-server
          PublicKey = "rMain0t9J0YeJR9AjuLuX6WL0Mh5QkFA2lxq/XV9RH4=";
          AllowedIPs = [
            "${ipPrefix}.2/32"
          ];
        }
      ];
    };
  };
}
