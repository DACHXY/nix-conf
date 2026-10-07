{ ... }:
{
  flake.modules.nixos.danny-gui =
    { config, ... }:
    {
      home-manager.users.${config.my.user.name} =
        { config, ... }:
        let
          cfg = config.wm;
          bindCfg = cfg.keybinds;
          inherit (bindCfg) mod;
          sep = bindCfg.separator;
        in
        {
          programs.niri.settings = {
            hotkey-overlay = {
              skip-at-startup = true;
              hide-not-bound = true;
            };
          };

          wm.keybinds.spawn = {
            "${mod}${sep}T" = "${cfg.app.terminal.run} vyo";
          };
        };
    };
}
