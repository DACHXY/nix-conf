{ config, ... }:
let
  inherit (config.flake.public.config.machines) dn-cscc dn-server gcp;
in
{
  configurations.nixos.dn-server.module =
    { config, lib, pkgs, ... }:
    let
      # The NixOS wg-quick module, when `configFile` is used, copies the file to
      # /tmp/<iface>.conf at start inside a PrivateTmp namespace. `preStop` then
      # runs in a fresh namespace where that copy no longer exists, so the stop
      # fails (`/tmp/wgN.conf does not exist`) and the interface is left up; the
      # next start then aborts with "`wgN' already exists". Re-copy the secret
      # before tearing the interface down so stop/restart (incl. nixos-rebuild)
      # works.
      mkPreStop =
        iface: ''
          cp ${config.sops.secrets."wireguard/${iface}.conf".path} /tmp/${iface}.conf
          ${pkgs.wireguard-tools}/bin/wg-quick down /tmp/${iface}.conf
        '';
    in
    {
      sops.secrets."wireguard/wg1.conf" = { };
      sops.secrets."wireguard/wg2.conf" = { };
      networking.wg-quick.interfaces.wg1.configFile = config.sops.secrets."wireguard/wg1.conf".path;
      networking.wg-quick.interfaces.wg2.configFile = config.sops.secrets."wireguard/wg2.conf".path;
      systemd.services."wg-quick-wg1".preStop = lib.mkForce (mkPreStop "wg1");
      systemd.services."wg-quick-wg2".preStop = lib.mkForce (mkPreStop "wg2");

      # Server endpoint for dn-cscc. Native module (not wg-quick) so it is not
      # affected by the config-file PrivateTmp issue above.
      sops.secrets."dn-server-key" = {
        sopsFile = ../../config/wg-cscc.yaml;
      };

      networking.firewall.allowedUDPPorts = [ dn-server.wg.wg0.listenPort ];

      networking.wireguard.interfaces.wg0 = {
        ips = [ "${dn-server.wg.wg0.ip}/24" ];
        listenPort = dn-server.wg.wg0.listenPort;
        privateKeyFile = config.sops.secrets."dn-server-key".path;
        peers = [
          {
            publicKey = dn-cscc.wg.wg0.publicKey;
            allowedIPs = [ "${dn-cscc.wg.wg0.ip}/32" ];
          }
          # dn-gcp dials in from GCE. allowedIPs is a /32 so it can only ever
          # source that one address on the tunnel.
          {
            publicKey = gcp.wg.wg0.publicKey;
            allowedIPs = [ "${gcp.wg.wg0.ip}/32" ];
          }
        ];
      };

      # dn-gcp is a cloud box; it gets to talk to dn-server and to nothing else
      # on the wg network. Both ends pin allowedIPs to a /32. The dropped
      # forwarding lives in firewall.nix: `extraForwardRules` is a no-op here
      # because the nftables firewall only renders the `forward` chain when
      # `networking.firewall.filterForward` is on (default: off).
    };
}
