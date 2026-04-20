{
  pkgs,
  config,
  ...
}:
let
  inherit (config.systemConf) username;
in
{
  sops.secrets."u2f_keys" = {
    sopsFile = ../../public/sops/dn-secret.yaml;
    owner = username;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.udev.packages = [ pkgs.yubikey-personalization ];
  programs.yubikey-manager.enable = true;

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

  systemd.tmpfiles.rules = [
    "d /home/${username}/.config/Yubico - ${username} - - -"
    "L /home/${username}/.config/Yubico/u2f_keys - - - - ${config.sops.secrets."u2f_keys".path}"
  ];
}
