{
  flake.modules.nixos.base =
    { config, pkgs, ... }:
    {
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        pinentryPackage = pkgs.pinentry-curses;
      };

      security.sudo-rs = {
        enable = true;
        execWheelOnly = true;
        extraConfig = ''
          Defaults timestamp_timeout=1
        '';
      };

      security.sudo.enable = !config.security.sudo-rs.enable;

      # `reboot` / `poweroff` go through systemd-logind, which asks polkit.
      # polkit's own default is `allow_active = yes`, but that only covers
      # sessions polkit considers active (a detached or extra ssh session is
      # not). Allow wheel unconditionally so `ssh host reboot` never prompts.
      security.polkit.extraConfig = /* js */ ''
        polkit.addRule(function(action, subject) {
          var actions = [
            "org.freedesktop.login1.reboot",
            "org.freedesktop.login1.reboot-multiple-sessions",
            "org.freedesktop.login1.reboot-ignore-inhibit",
            "org.freedesktop.login1.power-off",
            "org.freedesktop.login1.power-off-multiple-sessions",
            "org.freedesktop.login1.power-off-ignore-inhibit"
          ];
          if (actions.indexOf(action.id) !== -1 && subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';
    };
}
