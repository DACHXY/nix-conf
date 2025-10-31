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
    domain = "net.dn";
    hyprland.enable = false;
    security = {
      allowedDomains = [
        "github.com"
        "cache.nixos.org"
        "hyprland.cachix.org"
        "maps.rspamd.com"
        "cdn-hub.crowdsec.net"
        "api.crowdsec.net"
      ];
      allowedIPs = [
        "10.0.0.0/24"
        "127.0.0.1"
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
