{
  flake.modules.nixos.danny =
    { config, pkgs, ... }:
    let
      # sudo resolves symlinks before matching, so a rule naming
      # /run/current-system/sw/bin/<name> can never match: that directory is a
      # symlink farm. Match the real store path instead.
      goWin = pkgs.callPackage ../../../scripts/goWin.nix { };
    in
    {
      # `reboot` / `poweroff` need no sudo at all — plain `reboot` goes through
      # systemd-logind, and security.polkit.extraConfig (modules/security.nix)
      # authorises wheel for those actions.
      security.sudo-rs.extraRules = [
        {
          users = [ config.my.user.name ];
          commands = [
            {
              command = "${goWin}/bin/goWin";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };
}
