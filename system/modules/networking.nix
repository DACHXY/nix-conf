{
  networking = {
    networkmanager.enable = true;
    enableIPv6 = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 8099 ];
    };
  };
}
