{ pkgs, ... }:

{
  services.udev.packages = [ pkgs.yubikey-personalization ];

  security.pam = {
    services.hyprlock = { };
    services = {
      sudo.u2fAuth = true;
    };

    u2f = {
      enable = true;
      settings.cue = true;
      control = "sufficient";
    };
  };

  environment.systemPackages = with pkgs; [
    yubikey-manager
  ];
}
