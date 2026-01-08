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
