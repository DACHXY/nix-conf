{
  flake.modules.nixos.danny =
    { config, pkgs, ... }:
    let
      username = config.my.user.name;
    in
    {
      # FIDO key handles for pam_u2f; every host needs them, so they live in
      # common.yaml, which (unlike secret.yaml) dn-server and dn-cc can read.
      sops.secrets."u2f_keys" = {
        sopsFile = ./common.yaml;
        owner = username;
      };

      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };

      services.udev.packages = [ pkgs.yubikey-personalization ];
      programs.yubikey-manager.enable = true;

      programs.yubikey-touch-detector.enable = true;

      # In the u2f services the password is asked BEFORE pam_u2f: nh (and any
      # `sudo -S`) pipes the account password on stdin, and with pam_u2f first
      # and pinverification on, that password was read as the FIDO PIN and
      # burned PIN retries (8 wrong PINs lock the key). Interactively, press
      # Enter at the password prompt to fall through to PIN + touch.
      security.pam = {
        # pam_u2f only where it replaces the password for privilege: sudo and
        # polkit. With u2f.enable on globally, NixOS put it (as "sufficient")
        # in every PAM service -- passwd/chsh, run0, login, screen lockers --
        # so a touch alone could change the password or log in.
        services = {
          sudo-i = {
            u2f.enable = true;
            rules.auth.u2f.order = config.security.pam.services."sudo-i".rules.auth.unix.order + 50;
          };
          polkit-1 = {
            u2f.enable = true;
            rules.auth.u2f.order = config.security.pam.services."polkit-1".rules.auth.unix.order + 50;
          };
          sudo = {
            u2f.enable = true;
            rules.auth.u2f.order = config.security.pam.services.sudo.rules.auth.unix.order + 50;
            # A signature made by the *client's* ssh-agent satisfies sudo, so
            # `nh os switch --target-host` / `nixos-rebuild --use-remote-sudo`
            # needs a touch on the FIDO key instead of a password.
            # pam_rssh, not pam_ssh_agent_auth: only the former knows the
            # sk-ecdsa-sha2-nistp256@openssh.com key type.
            rssh = true;
          };
        };
        u2f = {
          # Global default for every service; the three above opt in.
          enable = false;
          control = "sufficient";
          settings = {
            cue = true;
            origin = "pam://dn-yubikey";
            userpresence = 1;
            # Touch AND the FIDO PIN: a process running as danny can trigger
            # a sudo prompt, so a reflexive touch must not be enough for root.
            pinverification = 1;
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
        sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBEU4+o6X7HT/i1hJuB8kOZ2BBxEuM0RTZrrDo8gsYZUkVFleYl1dvR09+nQLqRLbcmPfe9ebGxhfjEJCkxkQgg4AAAAEc3NoOg== danny@fido-rp2350a
        sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBJ3AkhPMtjvOoDCV0+of0MNYPyzw5bshx3WVrkB5VEG0+WDy5BCAn13nHAZqbj4c0CYtKPRySACbhtD7ydMw2OAAAAAEc3NoOg== danny@fido-rp2040
        sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBJ2hYWaqYbYwzDqmNXhWXA/iabMUXiRNRvZwsIU9YcB2YVw7L2BfyhZfJux7PWFPYyrM5HCPzHGUAjevOIsVpH0AAAAEc3NoOg== danny@fido-rp2350b
      '';

      systemd.tmpfiles.rules = [
        "d /home/${username}/.config/Yubico - ${username} - - -"
        "L /home/${username}/.config/Yubico/u2f_keys - - - - ${config.sops.secrets."u2f_keys".path}"
      ];
    };
}
