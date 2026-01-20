{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    getExe
    pipe
    ;
  inherit (builtins) fetchurl genList listToAttrs;
  inherit (config.systemConf) username;

  # nvidia-offload-enabled = config.hardware.nvidia.prime.offload.enableOffloadCmd;
  prefix = "nvidia-offload";
  terminal = "ghostty";
  browser = "zen-twilight";

  brightnessStep = toString 10;
  volumeStep = toString 4;

  execOnceScript = pkgs.writeShellScript "startupExec" ''
    # Fix nemo open in terminal
    dconf write /org/cinnamon/desktop/applications/terminal/exec "''\'${terminal}''\'" &
    dconf write /org/cinnamon/desktop/applications/terminal/exec-arg "''\'''\'" &

    # Hint dark theme
    dconf write /org/gnome/desktop/interface/color-scheme '"prefer-dark"' &

    systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORMTHEME &
  '';

  niri_peekaboo = fetchurl {
    url = "https://raw.githubusercontent.com/heyoeyo/niri_tweaks/refs/heads/main/niri_peekaboo.py";
    sha256 = "sha256:0l1x0bsa9vr089jhzgcz3xbh1hg15sw6njb91q0j9pdbrp2ym3dc";
  };
in
{
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  home-manager.users."${username}" =
    {
      osConfig,
      config,
      ...
    }:
    let
      rofiWall = import ../../home/scripts/rofiwall.nix { inherit config pkgs; };
      rbwSelector = import ../../home/scripts/rbwSelector.nix { inherit pkgs; };
      rNiri = pkgs.writeShellScriptBin "rNiri" ''
        NIRI_SOCKET="/run/user/1000/$(ls /run/user/1000 | grep niri | head -n 1)" niri $@
      '';
      toggleWlogout = pkgs.writeShellScript "toggleWlogout" ''
        if ${pkgs.busybox}/bin/pgrep wlogout > /dev/null; then
          ${pkgs.busybox}/bin/pkill wlogout
        else
           ${config.programs.wlogout.package}/bin/wlogout --protocol layer-shell
        fi
      '';
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
          { argv = [ "${execOnceScript}" ]; }
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
            from = "#24273A";
            to = "#EBDBB2";
            angle = 45;
            in' = "oklab";
            relative-to = "window";
          };
          inactive.gradient = {
            from = "#24273A";
            to = "#24273A";
            angle = 45;
            in' = "oklab";
            relative-to = "window";
          };
        };

        window-rules = [
          # Global
          {
            geometry-corner-radius =
              let
                round = 12.0;
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
            repeat-delay = 250;
            repeat-rate = 35;
          };
        };

        binds =
          let
            sh = spawn "sh" "-c";
          in
          {
            # ==== Launch ==== #
            "Mod+Return".action = sh "${prefix} ${terminal}";
            "Mod+F".action = sh "${browser}";
            "Mod+E".action = sh "${prefix} ${terminal} -e yazi";
            "Mod+Ctrl+P".action = spawn "${rbwSelector}";
            "Mod+Ctrl+M".action = spawn "${toggleWlogout}";

            # Rofi
            "Mod+Ctrl+W".action = spawn "${rofiWall}";
            "Alt+Space".action = spawn "rofi" "-config" "~/.config/rofi/apps.rasi" "-show" "drun";
            "Mod+Period".action = spawn "rofi" "-modi" "emoji" "-show" "emoji";
            "Mod+Ctrl+C".action = spawn "rofi" "-modi" "calc" "-show" "calc" "-no-show-match" "-no-sort";

            # ==== Media ==== #
            "XF86AudioPrev".action = spawn "playerctl" "previous";
            "XF86AudioNext".action = spawn "playerctl" "next";
            "Mod+Ctrl+Comma".action = spawn "playerctl" "previous";
            "Mod+Ctrl+Period".action = spawn "playerctl" "next";
            "XF86AudioPlay".action = spawn "playerctl" "play-pause";
            "XF86AudioStop".action = spawn "playerctl" "stop";
            "XF86AudioMute".action = spawn "wpctl" "set-mute" "@DEFAULT_SINK@" "toggle";
            "XF86AudioRaiseVolume".action =
              sh "wpctl set-mute @DEFAULT_SINK@ 0 && wpctl set-volume @DEFAULT_SINK@ ${volumeStep}%+";
            "XF86AudioLowerVolume".action =
              sh "wpctl set-mute @DEFAULT_SINK@ 0 && wpctl set-volume @DEFAULT_SINK@ ${volumeStep}%-";
            "XF86MonBrightnessDown".action = spawn "brightnessctl set ${brightnessStep}%-";
            "XF86MonBrightnessUp".action = spawn "brightnessctl set ${brightnessStep}%+";

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
            "Mod+Ctrl+H".action = focus-monitor-left;
            "Mod+Ctrl+L".action = focus-monitor-right;

            # Workspace Focus
            "Mod+Ctrl+J".action = focus-workspace-down;
            "Mod+Ctrl+K".action = focus-workspace-up;

            # General Focus
            "Mod+J".action = focus-window-or-workspace-down;
            "Mod+K".action = focus-window-or-workspace-up;
            "Mod+H".action = focus-column-or-monitor-left;
            "Mod+L".action = focus-column-or-monitor-right;

            # Workspace Move
            "Mod+Ctrl+Shift+J".action = move-workspace-down;
            "Mod+Ctrl+Shift+K".action = move-workspace-up;

            # Window & Column Move
            "Mod+Shift+J".action = move-window-down-or-to-workspace-down;
            "Mod+Shift+K".action = move-window-up-or-to-workspace-up;
            "Mod+Shift+L".action = move-column-right-or-to-monitor-right;
            "Mod+Shift+H".action = move-column-left-or-to-monitor-left;

            # Window Comsume
            "Mod+Ctrl+Shift+L".action = consume-or-expel-window-right;
            "Mod+Ctrl+Shift+H".action = consume-or-expel-window-left;

            # ==== Action ==== #
            # General
            "Mod+C".action = center-window;
            "Mod+O".action = toggle-overview;
            "Mod+Q".action = close-window;
            "F11".action = if config.services.nfsm.enable then (spawn "nfsm-cli") else fullscreen-window;
            "Mod+Shift+slash".action = show-hotkey-overlay;
            "Mod+Ctrl+Shift+P".action = spawn "${getExe pkgs.python312}" "${niri_peekaboo}";

            # Column Scale
            "Mod+W".action = switch-preset-column-width;
            "Mod+S".action = switch-preset-window-height;
            "Mod+P".action = expand-column-to-available-width;
            "Mod+M".action = maximize-column;
            "Mod+Ctrl+S".action = reset-window-height;

            # Float
            "Mod+V".action = toggle-window-floating;
            "Mod+Ctrl+V".action = switch-focus-between-floating-and-tiling;

            # Screenshot
            "Mod+Shift+S".action.screenshot = [ { show-pointer = false; } ];
            "Ctrl+Shift+S".action.screenshot-window = [
              {
                write-to-disk = false;
              }
            ];
            "Mod+Ctrl+Shift+S".action.screenshot-screen = [
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
                name = "Mod+${toString i}";
                value.action = focus-workspace i;
              }) x
            )
            (x: listToAttrs x)
          ]);
      };
    };
}
