# GCE hands out the address over DHCP on ens4 (gateway 10.128.0.1, DNS and the
# metadata route via 169.254.169.254, MTU 1460 as DHCP option 26 — networkd
# applies it). Addresses are not pinned here on purpose: the instance keeps its
# ephemeral internal IP across a reinstall.
{
  configurations.nixos.dn-gcp.module = {
    networking = {
      useNetworkd = true;
    };

    systemd.network.networks."10-wan" = {
      matchConfig.Type = "ether";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = false;
      };
      dhcpV4Config.UseMTU = true;
    };
  };
}
