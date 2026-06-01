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
        };
      };
    };
}
