{
  # dn-server sits on the home LAN; the router forwards only 443, 993, 30072
  # and the WireGuard port to it, and dn-cc proxies the rest over wg2. Instead
  # of every module opening its ports on all interfaces, each port is opened
  # only where its clients are. The nftables table in firewall.nix still
  # allowlists SSH sources and only lets dn-cc talk SMTP.
  #
  # The global lists are mkForce'd, so a port another module opens on all
  # interfaces (e.g. a new service's `openFirewall = true`) stays CLOSED on
  # dn-server until it is added to one of the lists below.
  configurations.nixos.dn-server.module =
    { lib, ... }:
    let
      lan = [
        "enp0s31f6"
        "wlp0s20f3"
      ];
      private = [
        "wg1"
        "wg2"
        "nb-wt0"
        "podman*"
      ];

      # Reachable from anywhere (router forwards / public RTC).
      globalTCP = [
        22 # sshd (also on 30072); source-filtered by ssh-filter
        30072 # sshd, forwarded by the router; source-filtered by ssh-filter
        443 # nginx: forwarded by the router and proxied by dn-cc
        993 # IMAPS, forwarded by the router
        7880 # LiveKit
      ];
      globalUDP = [
        51821 # WireGuard wg0 (dn-cscc)
        51830 # NetBird relay
      ];
      globalUDPRanges = [
        {
          from = 50000;
          to = 51000;
        } # LiveKit RTC
      ];

      # Only dn-cc, over wg2.
      fromCC = [
        25 # SMTP relay (smtp-filter also pins the source to dn-cc)
        80
        389 # OpenLDAP replication to dn-cc
        465
        8011 # NetBird management (gRPC via dn-cc nginx)
        8012 # NetBird signal
        32011 # NetBird
        8448 # Matrix federation
      ];

      # VPN peers and containers.
      privateTCP = [
        53 # PowerDNS
        636 # LDAPS
        8044 # homepage
        32006 # forgejo HTTP
      ];
      privateUDP = [ 53 ];

      # Home LAN only: game streaming and the greeter remote control.
      lanTCP = [
        27015 # Steam dedicated server
        27036 # Steam Remote Play
        27037
        27040 # Steam local game transfers
        30025 # greetd control (no auth; also source-checked in-app)
        47990 # punktfunk management
        47992
        47993
      ];
      lanUDP = [
        5353 # mDNS
        9777 # punktfunk
        9778
        10400
        10401
        27015
        27036
      ];
      lanUDPRanges = [
        {
          from = 27031;
          to = 27035;
        } # Steam Remote Play
      ];

      forIfaces =
        ifaces: rules:
        lib.genAttrs ifaces (_: {
          allowedTCPPorts = rules.tcp or [ ];
          allowedUDPPorts = rules.udp or [ ];
          allowedUDPPortRanges = rules.udpRanges or [ ];
        });
    in
    {
      networking.firewall = {
        allowedTCPPorts = lib.mkForce globalTCP;
        allowedUDPPorts = lib.mkForce globalUDP;
        allowedTCPPortRanges = lib.mkForce [ ];
        allowedUDPPortRanges = lib.mkForce globalUDPRanges;

        interfaces = lib.mkMerge [
          (forIfaces [ "wg2" ] { tcp = fromCC; })
          (forIfaces private {
            tcp = privateTCP;
            udp = privateUDP;
          })
          (forIfaces lan {
            tcp = lanTCP;
            udp = lanUDP;
            udpRanges = lanUDPRanges;
          })
        ];
      };
    };
}
