{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    getExe
    mkIf
    pipe
    mapAttrs
    ;
  inherit (builtins) fetchurl genList listToAttrs;
  inherit (config.systemConf) username;

  niri_peekaboo = fetchurl {
    url = "https://raw.githubusercontent.com/heyoeyo/niri_tweaks/refs/heads/main/niri_peekaboo.py";
    sha256 = "sha256:0l1x0bsa9vr089jhzgcz3xbh1hg15sw6njb91q0j9pdbrp2ym3dc";
  };
in
{
  config = mkIf config.programs.niri.enable {
    programs.niri = {
      package = pkgs.niri-unstable;
    };

    home-manager.users."${username}" =
      {
        osConfig,
        config,
        ...
      }:
      let
        rNiri = pkgs.writeShellScriptBin "rNiri" ''
          NIRI_SOCKET="/run/user/1000/$(ls /run/user/1000 | grep niri | head -n 1)" niri $@
        '';
        wmCfg = config.wm;
        bindCfg = wmCfg.keybinds;
      in
      with config.lib.niri.actions;
      {
        home.packages = with pkgs; [
          nautilus # xdg-desktop-portal-gnome file picker
          rNiri
        ];

        xdg.portal = {
          extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
        };

        services.nfsm.enable = true;

        programs.niri.package = osConfig.programs.niri.package;
        programs.niri.settings = {
          spawn-at-startup = [
            { argv = [ "${wmCfg.exec-once}" ]; }
          ];
          screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png";

          prefer-no-csd = true;

          xwayland-satellite = {
            enable = true;
            path = getExe pkgs.xwayland-satellite-unstable;
          };

          animations = {
            workspace-switch.kind.spring = {
              damping-ratio = 1.0;
              stiffness = 1000;
              epsilon = 0.0001;
            };

            window-open.kind.easing = {
              duration-ms = 150;
              curve = "ease-out-expo";
            };

            window-close.kind.easing = {
              duration-ms = 150;
              curve = "ease-out-quad";
            };

            window-resize.kind.spring = {
              damping-ratio = 1.0;
              stiffness = 800;
              epsilon = 0.0001;
            };
          };

          layout.border = {
            enable = true;
            width = 4;
            active.gradient = {
              from = wmCfg.border.active.from;
              to = wmCfg.border.active.to;
              angle = wmCfg.border.active.angle;
              in' = "oklab";
              relative-to = "window";
            };
            inactive.gradient = {
              from = wmCfg.border.inactive.from;
              to = wmCfg.border.inactive.to;
              angle = wmCfg.border.inactive.angle;
              in' = "oklab";
              relative-to = "window";
            };
          };

          window-rules = [
            # Global
            {
              geometry-corner-radius =
                let
                  round = wmCfg.border.radius + 0.0;
                in
                {
                  bottom-left = round;
                  bottom-right = round;
                  top-left = round;
                  top-right = round;
                };
              clip-to-geometry = true;
              opacity = 1.0;
              draw-border-with-background = false;
            }
            # Float
            {
              matches = [
                { app-id = "^xdg-desktop-portal-gtk$"; }
                { app-id = "^(org.gnome.Nautilus)$"; }
                { app-id = "^(org.gnome.Loupe)$"; }
              ];
              open-floating = true;
            }
          ];

          input = {
            focus-follows-mouse = {
              max-scroll-amount = "90%";
              enable = true;
            };
            mouse.accel-speed = -0.1;
            keyboard = {
              repeat-delay = wmCfg.input.keyboard.repeat-delay;
              repeat-rate = wmCfg.input.keyboard.repeat-rate;
            };
          };

          binds =
            let
              sh = spawn "sh" "-c";
              spawnKeybinds = mapAttrs (name: value: {
                action = sh value;
              }) (wmCfg.keybinds.spawn-repeat // wmCfg.keybinds.spawn);
            in
            spawnKeybinds
            // {
              # ==== Movement ==== #
              # Mouse Scroll
              "Mod+WheelScrollDown" = {
                cooldown-ms = 150;
                action = focus-workspace-down;
              };
              "Mod+WheelScrollUp" = {
                cooldown-ms = 150;
                action = focus-workspace-up;
              };
              "Mod+Shift+WheelScrollDown" = {
                cooldown-ms = 150;
                action = focus-column-or-monitor-right;
              };
              "Mod+Shift+WheelScrollUp" = {
                cooldown-ms = 150;
                action = focus-column-or-monitor-left;
              };
              "Mod+WheelScrollRight".action = focus-column-right;
              "Mod+WheelScrollLeft".action = focus-column-left;

              # Touchpad
              "Mod+TouchpadScrollDown" = {
                cooldown-ms = 150;
                action = focus-window-or-workspace-down;
              };
              "Mod+TouchpadScrollUp" = {
                cooldown-ms = 150;
                action = focus-window-or-workspace-up;
              };

              # Monitor Focus
              "${bindCfg.move-monitor-focus.left}".action = focus-monitor-left;
              "${bindCfg.move-monitor-focus.right}".action = focus-monitor-right;

              # Workspace Focus
              "${bindCfg.move-workspace-focus.next}".action = focus-workspace-down;
              "${bindCfg.move-workspace-focus.prev}".action = focus-workspace-up;

              # General Focus
              "${bindCfg.move-window-focus.down}".action = focus-window-or-workspace-down;
              "${bindCfg.move-window-focus.up}".action = focus-window-or-workspace-up;
              "${bindCfg.move-window-focus.left}".action = focus-column-or-monitor-left;
              "${bindCfg.move-window-focus.right}".action = focus-column-or-monitor-right;

              # Workspace Move
              "${bindCfg.move-workspace.down}".action = move-workspace-down;
              "${bindCfg.move-workspace.up}".action = move-workspace-up;

              # Window & Column Move
              "${bindCfg.move-window.down}".action = move-window-down-or-to-workspace-down;
              "${bindCfg.move-window.up}".action = move-window-up-or-to-workspace-up;
              "${bindCfg.move-window.right}".action = move-column-right-or-to-monitor-right;
              "${bindCfg.move-window.left}".action = move-column-left-or-to-monitor-left;

              # Window Comsume
              "${bindCfg.consume-window.right}".action = consume-or-expel-window-right;
              "${bindCfg.consume-window.left}".action = consume-or-expel-window-left;

              # ==== Action ==== #
              # General
              "${bindCfg.center-window}".action = center-window;
              "${bindCfg.toggle-overview}".action = toggle-overview;
              "${bindCfg.close-window}".action = close-window;
              "${bindCfg.toggle-fullscreen}".action =
                if config.services.nfsm.enable then (spawn "nfsm-cli") else fullscreen-window;
              "Mod+Shift+slash".action = show-hotkey-overlay;
              "Mod+Ctrl+Shift+P".action = spawn "${getExe pkgs.python312}" "${niri_peekaboo}";

              # Column Scale
              "${bindCfg.switch-preset-column-width}".action = switch-preset-column-width;
              "${bindCfg.switch-preset-window-height}".action = switch-preset-window-height;
              "${bindCfg.expand-column-to-available-width}".action = expand-column-to-available-width;
              "${bindCfg.maximize-column}".action = maximize-column;
              "${bindCfg.reset-window-height}".action = reset-window-height;

              # Float
              "${bindCfg.toggle-float}".action = toggle-window-floating;
              "${bindCfg.switch-focus-between-floating-and-tiling}".action =
                switch-focus-between-floating-and-tiling;

              # Screenshot
              "${bindCfg.screenshot.area}".action.screenshot = [ { show-pointer = false; } ];
              "${bindCfg.screenshot.window}".action.screenshot-window = [
                {
                  write-to-disk = false;
                }
              ];
              "${bindCfg.screenshot.screen}".action.screenshot-screen = [
                {
                  write-to-disk = false;
                }
              ];
            }
            # Map Mod+{1 ~ 9} to workspace{1 ~ 9}
            // (pipe 9 [
              (x: genList (i: i + 1) x)
              (
                x:
                map (i: {
                  name = "${bindCfg.focus-workspace-prefix}+${toString i}";
                  value.action = focus-workspace i;
                }) x
              )
              (x: listToAttrs x)
            ]);
        };
      };

  };
}
