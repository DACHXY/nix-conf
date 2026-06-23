{ config, ... }:
let
  globalConfig = config;
in
{
  flake.modules.nixos.danny =
    { config, ... }:
    {
      home-manager.users.${config.my.user.name} =
        { config, ... }:
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
              {
                matches = [
                  { app-id = "^steam$"; }
                  { title = "^Steam Big Picture Mode$"; }
                ];
                open-floating = false;
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

          # ==== Noctalia Secrets === #
          sops.secrets."noctalia" = {
            sopsFile = ./secret.yaml;
            path = "${config.home.homeDirectory}/.local/state/noctalia/state.toml";
          };

          programs.noctalia.settings = {
            calendar.account = {
              danny_nextcloud = {
                name = "Nextcloud";
                provider = "custom";
                server_url = "${globalConfig.flake.public.config.services.nextcloud.endpoint}/remote.php/dav";
                type = "caldav";
                username = "dachxy";
              };

              personal_icloud = {
                color = "primary";
                name = "iCloud";
                provider = "icloud";
                type = "caldav";
                username = "Danny01161013@gmail.com";
              };
            };
          };
        };
    };
}
