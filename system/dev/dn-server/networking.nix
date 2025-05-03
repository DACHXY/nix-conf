{ ... }:
{
  networking = {
    domain = "net.dn";
    networkmanager.enable = true;
    enableIPv6 = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        443
        80
      ];
    };
  };
}
