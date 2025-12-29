{ hostname }:
{
  pkgs,
  ...
}:
let
  username = "danny";
in
{
  systemConf = {
    inherit hostname username;
    security = {
      allowedDomains = [
        "github.com"
        "cache.nixos.org"
        "hyprland.cachix.org"
        "maps.rspamd.com"
        "cdn-hub.crowdsec.net"
        "api.crowdsec.net"
        "mx1.daccc.info"
        "mx1.dnywe.com"
      ];
      allowedIPs = [
        "10.0.0.0/24"
        "127.0.0.1"
        # CrowdSec
        "52.51.161.146"
        "34.250.8.127"
      ];
      allowedIPv6 = [
        "ff02::/16"
        "fe80::/10"
        "::1"
      ];
      sourceIPs = [
        "10.0.0.1"
        "192.168.100.0/24"
      ];
    };
  };

  services.journald.extraConfig = ''
    SystemMaxUse=10G
    SystemKeepFree=100M
    MaxFileSec=1month
  '';

  imports = [
    ../public/dn
    ./common
    ./home
    ./network
    ./nix
    ./security
    ./services
    ./sops
    ./options
  ];

  environment.systemPackages = with pkgs; [
    openssl
  ];
}
