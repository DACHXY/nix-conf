{
  flake.modules.nixos.danny =
    { config, ... }:
    {
      security.sudo.extraRules = [
        {
          users = [ config.my.user.name ];
          commands = [
            {
              command = "/run/current-system/sw/bin/poweroff";
              options = [ "NOPASSWD" ];
            }
            {
              command = "/run/current-system/sw/bin/goWin";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };
}
