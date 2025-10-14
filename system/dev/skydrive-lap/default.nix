{ hostname }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = "skydrive";
in
{
  systemConf = {
    inherit hostname username;
    domain = "net.dn";
    hyprland = {
      enable = true;
      monitors = [
        {
          desc = "AU Optronics 0x82ED";
          props = "prefered, 0x0, 1";
          output = "eDP-1";
        }
        {
          desc = "AOC 24B30HM2 27ZQ4HA00101";
          props = "prefered, 1920x540, 1";
          output = "HDMI-A-2";
        }
      ];
    };
  };

  imports = [
    ../../modules/presets/basic.nix
    ./common
    ./games
    ./services
    ./sops
    ./utility
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
  ];

  users.users."${username}".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBDk8GmC7b9+XSDxnIj5brYmNLPVO47G5enrL3Q+8fuh 好強上的捷徑"
  ];
}
