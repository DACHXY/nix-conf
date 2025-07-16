{ pkgs, ... }:
{
  networking.firewall = {
    allowedTCPPorts = [
      7000
      7001
      7100
    ];
    allowedUDPPorts = [
      5353
      6000
      6001
      7011
    ];
  };

  environment.systemPackages = with pkgs; [
    uxplay
  ];

  systemd.user.services.uxplay = {
    serviceConfig = {
      ExecStart = "${pkgs.uxplay}/bin/uxplay -p";
    };
  };

  services.avahi = {
    enable = true;
    openFirewall = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
      domain = true;
    };
  };
}
