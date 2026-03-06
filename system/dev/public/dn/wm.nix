{ config, ... }:
let
  inherit (config.systemConf) username;
in
{
  home-manager.users."${username}" =
    { ... }:
    {
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
                title = "^.+$";
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
      wayland.windowManager.mango.settings = ''
        xkb_rules_options = caps:escape
      '';
    };
}
