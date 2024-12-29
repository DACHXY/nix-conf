{ pkgs, ... }:

{
  services.udev.packages = [ pkgs.yubikey-personalization ];

  security.pam.u2f = {
    enable = true;
    settings.cue = true;
    control = "sufficient";
  };

  security.pam.services = {
    greetd.u2fAuth = true;
    sudo.u2fAuth = true;
    # hyprlock.u2fAuth = true;
  };

  environment.systemPackages = with pkgs; [
    yubikey-manager
  ];
}
