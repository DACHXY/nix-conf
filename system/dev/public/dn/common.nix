{ config, ... }:
let
  inherit (config.systemConf) username;
in
{
  systemConf = {
    face = ../../../../home/config/.face;
    domain = "net.dn";
  };

  home-manager.users."${username}" =
    { ... }:
    {
      imports = [
        # Git
        (import ../../../../home/user/git.nix {
          inherit username;
          email = "Danny01161013@gmail.com";
        })
      ];

      # ==== Niri ==== #
      programs.niri.settings = {
        input.keyboard.xkb = {
          layout = "us";
          options = "caps:escape";
        };
        workspaces."game" = { };
        window-rules = [
          # Steam Game Fullscreen
          {
            matches = [
              {
                app-id = "^steam_app_(.*)$";
                is-floating = false;
              }
            ];
            open-fullscreen = true;
          }
          # Steam & Steam Game
          {
            matches = [
              { app-id = "^steam_app_*"; }
              { app-id = "^pioneergame.exe$"; }
              {
                app-id = "^steam$";
                title = "^Steam$";
              }
            ];
            open-on-workspace = "game";
          }
          # Steam Dialog float
          {
            matches = [
              { app-id = "^steam$"; }
              { title = "(.*)(EasyAntiCheat_EOS_Setup)(.*)"; }
              {
                app-id = "^pioneergame.exe$";
                title = "^$";
              }
            ];
            excludes = [
              {
                title = "^Steam$";
              }
            ];
            open-floating = true;
          }
        ];
      };
    };
}
