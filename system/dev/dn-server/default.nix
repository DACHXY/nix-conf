{ hostname }:
{
  pkgs,
  lib,
  inputs,
  system,
  config,
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
  };

  imports = [
    ./common
    ./home
    ./network
    ./nix
    ./security
    ./services
    ./sops
  ];

  environment.systemPackages = with pkgs; [
    openssl
  ];
}
