{ config, ... }:
let
  inherit (config.flake.public.config.machines) dn-server dn-cscc;
in
{
  configurations.nixos.dn-cscc.module =
    { config, ... }:
    {
      sops.secrets."dn-cscc-key" = {
        sopsFile = ../../config/wg-cscc.yaml;
      };

      networking.wireguard.interfaces.wg0 = {
        ips = [ "${dn-cscc.wg.wg0.ip}/24" ];
        privateKeyFile = config.sops.secrets."dn-cscc-key".path;
        peers = [
          {
            publicKey = dn-server.wg.wg0.publicKey;
            endpoint = "${config.server-rules.extra.dn-server.network.ipv4}:${toString dn-server.wg.wg0.listenPort}";
            allowedIPs = [ "10.30.0.0/24" ];
            persistentKeepalive = 25;
          }
        ];
      };
    };
}
