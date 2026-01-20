{ hostname }:
{
  pkgs,
  config,
  ...
}:
let
  inherit (config.networking) domain;
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
        "mx1.${domain}"
      ];
      allowedIPs = [
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

  users.users = {
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
    ];

    "${username}".openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
    ];
  };
}
