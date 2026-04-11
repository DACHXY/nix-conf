# Check: https://nix-community.github.io/lanzaboote/getting-started/prepare-your-system.html
{ pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    sbctl
  ];

  boot = {
    loader.systemd-boot.enable = lib.mkForce false;
    lanzaboote = {
      enable = true;
      autoGenerateKeys.enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
