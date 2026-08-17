{
  flake.modules.nixos.danny-gui =
    { config, ... }:
    {
      home-manager.users.${config.my.user.name} = {
        programs.niri.settings = {
          hotkey-overlay = {
            skip-at-startup = true;
            hide-not-bound = true;
          };
        };
      };
    };
}
