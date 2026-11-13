{
  # dn-cscc sits on the school network (eno1, shared with everyone in the
  # lab), so nothing is opened there. SSH, game streaming and LocalSend are
  # reached over NetBird, whose access policies govern nb-wt0 (the NetBird
  # client inserts `iifname nb-wt0 accept` into the host firewall). incus is
  # only reached by dn-server's nginx over wg0.
  #
  # The global lists are mkForce'd, so a port another module opens on all
  # interfaces stays CLOSED here until it is added below.
  configurations.nixos.dn-cscc.module =
    { lib, ... }:
    {
      networking.firewall = {
        allowedTCPPorts = lib.mkForce [ ];
        allowedUDPPorts = lib.mkForce [
          51820 # NetBird WireGuard (direct peer connections)
        ];
        allowedTCPPortRanges = lib.mkForce [ ];
        allowedUDPPortRanges = lib.mkForce [ ];

        interfaces.wg0.allowedTCPPorts = [
          22
          8443 # incus API, proxied by dn-server
        ];
      };
    };
}
