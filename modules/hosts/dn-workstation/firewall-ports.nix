{
  # dn-workstation: SSH, nginx, game streaming and mDNS are opened only on its
  # LAN (enp132s0); everything else (LocalSend, ...) goes over NetBird, whose
  # access policies govern nb-wt0 (the NetBird client inserts
  # `iifname nb-wt0 accept` into the host firewall).
  #
  # The global lists are mkForce'd, so a port another module opens on all
  # interfaces stays CLOSED here until it is added below.
  configurations.nixos.dn-workstation.module =
    { lib, ... }:
    {
      networking.firewall = {
        allowedTCPPorts = lib.mkForce [ ];
        allowedUDPPorts = lib.mkForce [
          51820 # NetBird WireGuard (direct peer connections)
        ];
        allowedTCPPortRanges = lib.mkForce [ ];
        allowedUDPPortRanges = lib.mkForce [ ];

        interfaces.enp132s0 = {
          allowedTCPPorts = [
            22
            80 # nginx
            443
            5134 # punktfunk
            47990
            47992
            47993
            27015 # Steam dedicated server
            27036 # Steam Remote Play
            27037
            27040 # Steam local game transfers
          ];
          allowedUDPPorts = [
            5353 # mDNS (punktfunk / Steam discovery)
            9777 # punktfunk
            9778
            10400
            10401
            27015
            27036
          ];
          allowedUDPPortRanges = [
            {
              from = 27031;
              to = 27035;
            } # Steam Remote Play
          ];
        };
      };
    };
}
