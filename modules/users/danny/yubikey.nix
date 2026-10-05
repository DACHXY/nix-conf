{
  flake.modules.nixos.danny =
    { config, pkgs, ... }:
    let
      username = config.my.user.name;
    in
    {
      sops.secrets."u2f_keys" = {
        sopsFile = ./secret.yaml;
        owner = username;
      };

      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };

      services.udev.packages = [ pkgs.yubikey-personalization ];
      programs.yubikey-manager.enable = true;

      programs.yubikey-touch-detector.enable = true;

      security.pam = {
        services.hyprlock = {
          u2fAuth = false;
        };
        services = {
          sudo.u2fAuth = true;
          login.u2fAuth = true;
        };
        u2f = {
          enable = true;
          control = "sufficient";
          settings = {
            cue = true;
            origin = "pam://dn-yubikey";
            userpresence = 1;
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d /home/${username}/.config/Yubico - ${username} - - -"
        "L /home/${username}/.config/Yubico/u2f_keys - - - - ${config.sops.secrets."u2f_keys".path}"
      ];
    };
}
