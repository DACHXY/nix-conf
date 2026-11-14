{ config, ... }:
{
  flake.modules.nixos.danny-gui =
    { config, ... }:
    {
      home-manager.users.${config.my.user.name} = {
        # Steam: games fullscreen, client + games on workspace 9 (the old niri
        # "game" workspace), toasts bottom-right, dialogs floating.
        wm.umbriel.window-rules = [
          # Zen promotes extension panels (the Bitwarden toolbar popup) to a
          # real xdg_toplevel, so Umbriel tiles it into a 480px column. Float
          # and center it instead; with default_position set it stays put, and
          # the explicit size keeps the panel from inheriting a tiled extent.
          {
            match = {
              app_id = "^zen-twilight$";
              title = "^Extension: \\(Bitwarden";
            };
            default_floating = true;
            default_floating_size_px = {
              width = 420;
              height = 700;
            };
            default_position = {
              x = 0;
              y = 0;
              anchor = "center";
            };
          }
          # Steam Game Fullscreen
          {
            match = {
              app_id = "^steam_app_(.*)$";
              title = "^.+$";
              is_floating = false;
            };
            default_fullscreen = true;
          }
          # Steam & Steam Game -> workspace 9
          {
            match.app_id = [
              "^steam_app_.*$"
              "^pioneergame.exe$"
            ];
            default_workspace = 9;
          }
          {
            match = {
              app_id = "^steam$";
              title = "^Steam$";
            };
            default_workspace = 9;
          }
          # Steam Big Picture must tile
          {
            match.title = "^Steam Big Picture Mode$";
            default_floating = false;
          }
          # Friend/activity toasts are plain X11 toplevels; pin bottom-right.
          {
            match = {
              app_id = "^steam$";
              title = "^notificationtoasts_[0-9]+_desktop$";
            };
            default_floating = true;
            default_position = {
              x = 20;
              y = 20;
              anchor = "bottom_right";
            };
          }
          # Steam dialogs float (never the main client window).
          {
            match = {
              app_id = "^steam$";
              is_dialog = true;
            };
            default_floating = true;
          }
          {
            match.title = ".*EasyAntiCheat_EOS_Setup.*";
            default_floating = true;
          }
          {
            match = {
              app_id = "^pioneergame.exe$";
              title = "^$";
            };
            default_floating = true;
          }
        ];
      };
    };
}
