{
  flake.modules.nixos.incus =
    { config, pkgs, ... }:
    let
      username = config.my.user.name;
    in
    {
      # https://wiki.nixos.org/wiki/Incus
      virtualisation.incus = {
        enable = true;
        ui.enable = true;

        # Pre-seed the storage pool, bridge network and default profile so
        # `incus admin init` is not needed on a fresh install.
        preseed = {
          config = { };
          networks = [
            {
              name = "incusbr0";
              type = "bridge";
              config = {
                "ipv4.address" = "auto";
                "ipv4.nat" = "true";
                "ipv6.address" = "none";
              };
            }
          ];
          storage_pools = [
            {
              name = "default";
              driver = "dir";
              config.source = "/var/lib/incus/storage-pools/default";
            }
          ];
          profiles = [
            {
              name = "default";
              devices = {
                eth0 = {
                  name = "eth0";
                  network = "incusbr0";
                  type = "nic";
                };
                root = {
                  path = "/";
                  pool = "default";
                  type = "disk";
                };
              };
            }
          ];
        };
      };

      users.groups.incus-admin.members = [ username ];

      # Incus refuses to run on NixOS with the iptables firewall backend.
      networking.nftables.enable = true;

      # Incus UI / API endpoint (`incus config set core.https_address :8443`).
      networking.firewall.allowedTCPPorts = [ 8443 ];

      # dnsmasq serves DHCP and DNS for incusbr0 from the host itself, but the
      # generated `nixos-fw` input chain has policy drop and only whitelists
      # DHCPv4 in the rpfilter chain (not in input). Without these rules every
      # DHCP DISCOVER/REQUEST is discarded, so no instance ever gets a lease.
      networking.firewall.interfaces.incusbr0 = {
        allowedUDPPorts = [
          53
          67
        ];
        allowedTCPPorts = [ 53 ];
      };

      environment.systemPackages = [ pkgs.incus ];
    };
}
