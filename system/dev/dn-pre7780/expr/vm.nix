self: {
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network.networks."10-lan" = {
    matchConfig.Name = [
      "enp0s31f6"
      "vm-*"
    ];
    networkConfig = {
      Bridge = "br0";
    };
  };

  systemd.network.netdevs."br0" = {
    netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };
  };

  systemd.network.networks."10-lan-bridge" = {
    matchConfig.Name = "br0";
    networkConfig = {
      Address = [ "192.168.0.5/24" ];
      Gateway = "192.168.0.1";
      DNS = [ "192.168.0.1" ];
    };

    linkConfig.RequiredForOnline = "routable";
  };

  microvm.vms = {
    vm-1 = {
      flake = self;
      updateFlake = "git+file:///etc/nixos";
      autostart = false;
    };
    vm-2 = {
      flake = self;
      updateFlake = "git+file:///etc/nixos";
      autostart = false;
    };
  };
}
