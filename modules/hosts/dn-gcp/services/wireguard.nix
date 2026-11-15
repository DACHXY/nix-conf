# dn-gcp dials into dn-server's wg0 hub as a *client*. It is deliberately not a
# general member of the wg network: the peer allowedIPs on both sides are /32
# (10.30.0.1 <-> 10.30.0.3), so this tunnel can only carry traffic between
# dn-gcp and dn-server itself — never to dn-cscc or any other peer. dn-server
# additionally drops forwarded traffic to/from this address.
{ config, ... }:
let
  globalConfig = config;
  inherit (config.flake.public.config.machines) dn-server gcp;
in
{
  configurations.nixos.dn-gcp.module =
    { config, ... }:
    {
      sops.secrets."dn-gcp-key" = {
        sopsFile = ../../../config/wg-gcp.yaml;
      };

      networking.wireguard.interfaces.wg0 = {
        # A /32 address: dn-gcp gets no route into 10.30.0.0/24, the only route
        # the tunnel installs is dn-server's own /32 (its peer allowedIPs).
        ips = [ "${gcp.wg.wg0.ip}/32" ];
        privateKeyFile = config.sops.secrets."dn-gcp-key".path;
        peers = [
          {
            publicKey = dn-server.wg.wg0.publicKey;
            endpoint = "${config.server-rules.extra.dn-server.network.ipv4}:${toString dn-server.wg.wg0.listenPort}";
            # Only dn-server. Anything else is not in any peer's allowedIPs, so
            # wg refuses to put it on the wire even if a route says to.
            allowedIPs = [ "${dn-server.wg.wg0.ip}/32" ];
            persistentKeepalive = 25;
          }
        ];
      };
    };
}
