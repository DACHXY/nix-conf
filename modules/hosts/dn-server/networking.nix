{
  configurations.nixos.dn-server.module =
    { lib, ... }:
    {
      networking = {
        useDHCP = lib.mkDefault true;
        enableIPv6 = true;
        firewall.enable = true;

        networkmanager = {
          enable = true;
          insertNameservers = lib.mkForce [ "127.0.0.1" ];

          ensureProfiles.profiles."Wired connection 1" = {
            connection = {
              id = "Wired connection 1";
              type = "ethernet";
              interface-name = "enp0s31f6";
              uuid = "ca3f73e5-85b8-45cf-ae31-ca92f07f6887";
            };
            ipv4 = {
              method = "manual";
              addresses = "192.168.100.9/24";
              gateway = "192.168.100.1";
            };
          };
        };
      };
    };
}
