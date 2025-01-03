{ pkgs, ... }:

{
  services.udev.packages = [ pkgs.yubikey-personalization ];
  security.pam.services.hyprlock = { };
  security.pam.u2f = {
    enable = true;
    settings.cue = true;
    control = "sufficient";
  };

  security.pam.services = {
    sudo.u2fAuth = true;
  };

  environment.systemPackages = with pkgs; [
    yubikey-manager
  ];
}
