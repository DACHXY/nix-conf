{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.machines) dn-cc dn-server;
in
{
  configurations.nixos.dn-cc.module =
    { config, ... }:
    let
      listenPort = dn-cc.wg.wg0.listenPort;
      wgInterface = dn-cc.wg.wg0.interface;
      externalInterface = dn-cc.wg.wg0.externalInterface;
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
            DNS = [ dn-server.ip ];
            Domains = [ "~${domain}" ];
            IPv4Forwarding = true;
            IPv6Forwarding = true;
          };

          matchConfig.Name = wgInterface;
          address = [
            "${dn-cc.wg.wg0.ip}/32"
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
              PublicKey = dn-server.wg.wg1.publicKey;
              AllowedIPs = [
                "${dn-server.wg.wg1.ip}/32"
              ];
            }
          ];
        };
      };
    };
}
