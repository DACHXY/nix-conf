{
  flake.modules.nixos.gui =
    { config, ... }:
    {
      home-manager.users.${config.my.user.name} =
        {
          lib,
          config,
          pkgs,
          ...

        }:
        let
          inherit (lib)
            mkOption
            types
            concatStringsSep
            getExe
            dropEnd
            last
            mkEnableOption
            mapAttrs'
            nameValuePair
            splitString
            getExe'
            ;

          inherit (builtins) length;

          playerctl = getExe pkgs.playerctl;
          wpctl = getExe' pkgs.wireplumber "wpctl";
          brightnessctl = getExe pkgs.brightnessctl;
          brightnessStep = toString 10;
          volumeStep = toString 4;

          cfg = config.wm;
          bindCfg = cfg.keybinds;

          sep = bindCfg.separator;
          mod = bindCfg.mod;

          main-color = "#EBDBB2";
          secondary-color = "#24273A";

          mkHyprBind =
            keys:
            let
              len = length keys;
              prefix = if len > 1 then [ ] else [ "None" ];
              finalKeys = prefix ++ keys;
            in
            (concatStringsSep "+" (dropEnd 1 finalKeys)) + ",${last finalKeys}";

          mkBindOption =
            keys:
            let
              hypr-key = mkHyprBind keys;
            in
            mkOption {
              type = types.str;
              default = if bindCfg.hypr-type then hypr-key else (concatStringsSep sep keys);
            };

          mkGradientColorOption =
            {
              from ? main-color,
              to ? secondary-color,
              angle ? 45,
            }:
            {
              from = mkOption {
                type = types.str;
                default = from;
              };
              to = mkOption {
                type = types.str;
                default = to;
              };
              angle = mkOption {
                type = types.int;
                default = angle;
              };
            };
        in
        {
          options.wm = {
            exec-once = mkOption {
              type = with types; nullOr lines;
              default = /* bash */ ''
                dconf write /org/cinnamon/desktop/applications/terminal/exec "''\'${cfg.app.terminal.name}''\'" &
                dconf write /org/cinnamon/desktop/applications/terminal/exec-arg "''\'''\'" &

                # Hint dark theme
                dconf write /org/gnome/desktop/interface/color-scheme '"prefer-dark"' &

                systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORMTHEME &
              '';
              apply = v: if v != null then pkgs.writeShellScript "exec-once" v else null;
            };
            app = {
              file-browser = {
                package = mkOption {
                  type = with types; nullOr package;
                  default = config.programs.yazi.package;
                };
                name = mkOption {
                  type = with types; nullOr str;
                  default = "yazi";
                };
              };
              terminal = {
                package = mkOption {
                  type = with types; nullOr package;
                  default = config.programs.ghostty.package;
                };
                name = mkOption {
                  type = with types; nullOr str;
                  default = "ghostty";
                };
                run = mkOption {
                  type = with types; nullOr str;
                  default = "${getExe cfg.app.terminal.package} -e ";
                };
              };
              browser = {
                package = mkOption {
                  type = with types; nullOr package;
                  default = config.programs.zen-browser.package;
                };
                name = mkOption {
                  type = with types; nullOr str;
                  default = "zen-twilight";
                };
              };
            };
            window = {
              opacity = mkOption {
                type = types.float;
                default = 0.85;
              };
            };
            input = {
              keyboard = {
                repeat-delay = mkOption {
                  type = types.int;
                  default = 250;
                };
                repeat-rate = mkOption {
                  type = types.int;
                  default = 35;
                };
              };
            };
            border = {
              active = mkGradientColorOption { };
              inactive = mkGradientColorOption {
                from = secondary-color;
                to = secondary-color;
              };
              radius = mkOption {
                type = types.int;
                default = 12;
              };
            };
            keybinds = {
              mod = mkOption {
                type = types.str;
                default = "Mod";
              };
              separator = mkOption {
                type = types.str;
                default = "+";
              };
              hypr-type = mkEnableOption "hyprland-like bind syntax" // {
                default = false;
              };

              spawn = mkOption {
                type = types.attrs;
                default = {
                  "${mod}${sep}Return" = "${getExe cfg.app.terminal.package}";
                  "${mod}${sep}F" = "${getExe cfg.app.browser.package}";
                  "${mod}${sep}E" = "${cfg.app.terminal.run} ${cfg.app.file-browser.name}";
                };
                apply =
                  binds:
                  let
                    hypr-binds = mapAttrs' (n: v: nameValuePair (mkHyprBind (splitString sep n)) v) binds;
                  in
                  if bindCfg.hypr-type then hypr-binds else binds;
              };

              spawn-repeat = mkOption {
                type = types.attrs;
                default = {
                  # ==== Media ==== #
                  "XF86AudioPrev" = "${playerctl} previous";
                  "XF86AudioNext" = "${playerctl} next";
                  "${mod}${sep}CTRL${sep}COMMA" = "${playerctl} previous";
                  "${mod}${sep}CTRL${sep}PERIOD" = "${playerctl} next";
                  "XF86AudioPlay" = "${playerctl} play-pause";
                  "XF86AudioStop" = "${playerctl} stop";
                  "XF86AudioMute" = "${wpctl} set-mute @DEFAULT_SINK@ toggle";
                  "XF86AudioRaiseVolume" =
                    "${wpctl} set-mute @DEFAULT_SINK@ 0 && ${wpctl} set-volume @DEFAULT_SINK@ ${volumeStep}%+";
                  "XF86AudioLowerVolume" =
                    "${wpctl} set-mute @DEFAULT_SINK@ 0 && ${wpctl} set-volume @DEFAULT_SINK@ ${volumeStep}%-";
                  "XF86MonBrightnessDown" = "${brightnessctl} set ${brightnessStep}%-";
                  "XF86MonBrightnessUp" = "${brightnessctl} set ${brightnessStep}%+";
                };
                apply =
                  binds:
                  let
                    hypr-binds = mapAttrs' (n: v: nameValuePair (mkHyprBind (splitString sep n)) v) binds;
                  in
                  if bindCfg.hypr-type then hypr-binds else binds;
              };

              # ==== Movement ==== #
              switch-window-focus = mkBindOption [
                mod
                "TAB"
              ];
              move-window-focus = {
                left = mkBindOption [
                  mod
                  "H"
                ];
                right = mkBindOption [
                  mod
                  "L"
                ];
                up = mkBindOption [
                  mod
                  "K"
                ];
                down = mkBindOption [
                  mod
                  "J"
                ];
              };
              move-monitor-focus = {
                left = mkBindOption [
                  mod
                  "CTRL"
                  "H"
                ];
                right = mkBindOption [
                  mod
                  "CTRL"
                  "L"
                ];
              };
              move-workspace-focus = {
                # Workspace Focus
                next = mkBindOption [
                  mod
                  "CTRL"
                  "J"
                ];
                prev = mkBindOption [
                  mod
                  "CTRL"
                  "k"
                ];
              };
              move-window = {
                left = mkBindOption [
                  mod
                  "SHIFT"
                  "H"
                ];
                right = mkBindOption [
                  mod
                  "SHIFT"
                  "L"
                ];
                up = mkBindOption [
                  mod
                  "SHIFT"
                  "K"
                ];
                down = mkBindOption [
                  mod
                  "SHIFT"
                  "J"
                ];
              };

              consume-window = {
                left = mkBindOption [
                  mod
                  "CTRL"
                  "SHIFT"
                  "H"
                ];
                right = mkBindOption [
                  mod
                  "CTRL"
                  "SHIFT"
                  "L"
                ];
              };

              switch-layout = mkBindOption [
                mod
                "CTRL"
                "ALT"
                "SPACE"
              ];

              # ==== Actions ==== #
              center-window = mkBindOption [
                mod
                "C"
              ];
              toggle-overview = mkBindOption [
                mod
                "O"
              ];
              close-window = mkBindOption [
                mod
                "Q"
              ];
              toggle-fullscreen = mkBindOption [
                "F11"
              ];

              # ==== Scrolling ==== #
              move-workspace = {
                down = mkBindOption [
                  mod
                  "CTRL"
                  "SHIFT"
                  "J"
                ];
                up = mkBindOption [
                  mod
                  "CTRL"
                  "SHIFT"
                  "K"
                ];
              };

              switch-preset-column-width = mkBindOption [
                mod
                "W"
              ];
              switch-preset-window-height = mkBindOption [
                mod
                "S"
              ];
              expand-column-to-available-width = mkBindOption [
                mod
                "P"
              ];
              maximize-column = mkBindOption [
                mod
                "M"
              ];
              reset-window-height = mkBindOption [
                mod
                "CTRL"
                "S"
              ];

              # ==== Float ==== #
              toggle-float = mkBindOption [
                mod
                "V"
              ];
              switch-focus-between-floating-and-tiling = mkBindOption [
                mod
                "CTRL"
                "V"
              ];

              minimize = mkBindOption [
                mod
                "I"
              ];

              restore-minimize = mkBindOption [
                mod
                "SHIFT"
                "I"
              ];

              toggle-scratchpad = mkBindOption [
                mod
                "Z"
              ];

              # ==== Screenshot ==== #
              screenshot = {
                area = mkBindOption [
                  mod
                  "SHIFT"
                  "S"
                ];
                window = mkBindOption [
                  "CTRL"
                  "SHIFT"
                  "S"
                ];
                screen = mkBindOption [
                  mod
                  "CTRL"
                  "SHIFT"
                  "S"
                ];
              };

              toggle-control-center = mkBindOption [
                mod
                "SLASH"
              ];

              toggle-launcher = mkBindOption [
                "ALT"
                "SPACE"
              ];

              toggle-launcher-shortcuts = mkBindOption [
                mod
                "R"
              ];

              lock-screen = mkBindOption [
                mod
                "CTRL"
                "M"
              ];

              clipboard-history = mkBindOption [
                mod
                "COMMA"
              ];

              emoji = mkBindOption [
                mod
                "PERIOD"
              ];

              screen-recorder = mkBindOption [
                mod
                "F12"
              ];

              notification-center = mkBindOption [
                mod
                "N"
              ];

              toggle-dont-disturb = mkBindOption [
                mod
                "CTRL"
                "N"
              ];

              wallpaper-selector = mkBindOption [
                mod
                "CTRL"
                "W"
              ];

              wallpaper-random = mkBindOption [
                mod
                "CTRL"
                "SLASH"
              ];

              calculator = mkBindOption [
                mod
                "CTRL"
                "C"
              ];

              media = {
                prev = mkBindOption [
                  mod
                  "CTRL"
                  "COMMA"
                ];

                next = mkBindOption [
                  mod
                  "CTRL"
                  "PERIOD"
                ];
              };

              focus-workspace-prefix = mkBindOption [ mod ];
            };
          };
        };
    };
}
