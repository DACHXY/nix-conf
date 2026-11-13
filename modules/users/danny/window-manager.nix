{ config, ... }:
let
  globalConfig = config;
in
{
  flake.modules.nixos.danny-gui =
    { config, ... }:
    {
      # ==== Noctalia Secrets === #
      # Decrypted by the system sops-nix (root-only host key), owned by the user.
      sops.secrets."noctalia" = {
        sopsFile = ./secret.yaml;
        owner = config.my.user.name;
        mode = "0400";
        path = "${config.users.users.${config.my.user.name}.home}/.local/state/noctalia/state.toml";
      };

      services.keyd = {
        enable = true;
        keyboards.default.settings.main.capslock = "esc";
      };

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
              # Steam friend/activity notification toasts are plain X11
              # toplevels (Steam never sends them to the notification daemon),
              # so niri centers them; pin them to the bottom-right corner.
              # See niri wiki: Application Issues -> Steam.
              {
                matches = [
                  {
                    app-id = "^steam$";
                    title = "^notificationtoasts_[0-9]+_desktop$";
                  }
                ];
                open-floating = true;
                default-floating-position = {
                  x = 20;
                  y = 20;
                  relative-to = "bottom-right";
                };
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
                open-fullscreen = false;
              }
            ];
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
