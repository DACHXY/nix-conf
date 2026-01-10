{ config, ... }:
let
  inherit (config.systemConf) username;
in
{
  virtualisation.libvirtd.enable = true;
  users.extraUsers."${username}".extraGroups = [ "libvirtd" ];

  services.usbmuxd.enable = true;

  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options kvm_intel emulate_invalid_guest_state=0
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';

  systemd.network.enable = true;
  networking.useNetworkd = true;

  systemd.network.networks."10-lan" = {
    matchConfig.Name = [
      "enp0s31f6"
    ];
    networkConfig = {
      Bridge = "virbr0";
    };
  };

  systemd.network.netdevs."virbr0" = {
    netdevConfig = {
      Name = "virbr0";
      Kind = "bridge";
    };
  };

  systemd.network.networks."10-lan-bridge" = {
    matchConfig.Name = "virbr0";
    networkConfig = {
      Address = [ "192.168.0.5/24" ];
      Gateway = "192.168.0.1";
      DNS = [ "192.168.0.1" ];
    };
    linkConfig.RequiredForOnline = "routable";
  };

  environment.etc."qemu/bridge.conf".text = "allow virbr0\n";
}
