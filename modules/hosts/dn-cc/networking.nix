{
  configurations.nixos.dn-cc.module =
    { lib, config, ... }:
    let
      inherit (config.server-rules.extra.dn-cc.network) ipv4 gateway;
      prefix = 25;
    in
    {
      networking = {
        useNetworkd = true;
        nat.enableIPv6 = lib.mkForce false;
      };

      boot.kernelParams = [ "ipv6.disable=1" ];

      systemd.network.networks."10-wan" = {
        matchConfig.Type = "ether";

        address = [ "${ipv4}/${toString prefix}" ];
        gateway = [ gateway ];
        dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];
      };
    };
}
