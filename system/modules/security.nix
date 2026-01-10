{ pkgs, config, ... }:

{
  services.udev.packages = [ pkgs.yubikey-personalization ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
    extraConfig = ''
      Defaults timestamp_timeout=0
    '';
  };

  security.sudo.enable = !config.security.sudo-rs.enable;

  # ==== PAM u2f ===== #
  # $ nix shell nixpkgs#pam_u2f
  # $ mkdir -p ~/.config/Yubico
  # $ pamu2fcfg > ~/.config/Yubico/u2f_keys
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
      settings.cue = true;
      control = "sufficient";
    };
  };

  programs.yubikey-manager.enable = true;
}
