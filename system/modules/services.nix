{ config, pkgs, ... }:

{
  services = {
    dbus.enable = true;
    picom.enable = true;
    openssh.enable = true;

    xserver = {
      enable = true;
      xkb.layout = "us";
    };

    displayManager = {
      sddm.enable = true;
      sddm.theme = "${import ./sddm-theme.nix { inherit pkgs; }}";
    };
  };
}
