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
          sudo = {
            u2fAuth = true;
            # A signature made by the *client's* ssh-agent satisfies sudo, so
            # `nh os switch --target-host` / `nixos-rebuild --use-remote-sudo`
            # needs a touch on the FIDO key instead of a password.
            # pam_rssh, not pam_ssh_agent_auth: only the former knows the
            # sk-ecdsa-sha2-nistp256@openssh.com key type.
            rssh = true;
          };
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
        rssh = {
          enable = true;
          # Deliberately NOT the default (/etc/ssh/authorized_keys.d/$ruser):
          # that file lists every key in modules/users/danny/ssh.nix, including
          # file-backed ones that sign without any user interaction. Restrict
          # root's trusted list to the FIDO key so a touch is always required.
          settings.auth_key_file = "/etc/ssh/fido2_authorized_keys";
        };
      };

      # Root-owned and not user-writable: pam_rssh trusts this file to grant
      # root, so it must not be editable by the unprivileged user.
      environment.etc."ssh/fido2_authorized_keys".text = ''
        sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBLCh0RGSz3Bp5TAvmaIzt7uQzbYV0cwREdvE/tIoJIUPntsik+B0HB01jQu4HpWs4J8197xNKH+dKb2+m1AOIjIAAAAEc3NoOg== danny@fido
      '';

      systemd.tmpfiles.rules = [
        "d /home/${username}/.config/Yubico - ${username} - - -"
        "L /home/${username}/.config/Yubico/u2f_keys - - - - ${config.sops.secrets."u2f_keys".path}"
      ];
    };
}
