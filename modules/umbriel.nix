{ config, ... }:
let
  globalConfig = config;
in
{
  flake.modules.nixos.umbriel =
    { config, ... }:
    let
      inherit (config.my.user) name;
    in
    {
      programs.umbriel.enable = true;

      # Niri's portal config would otherwise stay the default inside an
      # Umbriel session (file pickers, screenshots).
      xdg.portal.config.umbriel.default = [
        "umbriel"
        "gtk"
      ];

      home-manager.users.${name}.imports = [
        globalConfig.flake.modules.homeManager.umbriel
      ];
    };

  flake.modules.homeManager.umbriel =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib)
        mapAttrs
        genList
        listToAttrs
        ;
      wmCfg = config.wm;
      bindCfg = wmCfg.keybinds;
      # warpd's teardown destroys the wl_surface before its layer-shell role
      # object; plain wlroots tolerated that, Umbriel's compositor implementation
      # answers with `surface was destroyed before its role object` and kills the
      # client, so the mouse-mode binds appeared to do nothing. The other three
      # patches are the ones niri already needs (see modules/niri.nix) -
      # scroll_left/copy-selection are used by the shared warpd config.
      warpdPatched = pkgs.warpd.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../patches/warpd-follow-output.patch
          ../patches/warpd-scroll-horizontal.patch
          ../patches/warpd-copy-selection.patch
          ../patches/warpd-layer-surface-destroy-order.patch
        ];
      });
      noctalia = cmd: "spawn noctalia msg ${cmd}";
      spawnBind = value: {
        action = "spawn ${value}";
        repeat = false;
      };
      repeatBind = value: {
        action = "spawn ${value}";
        repeat = true;
        allow_when_locked = true;
      };
      # Umbriel replaces its built-in bind set as soon as [keybinds] exists, so
      # everything that should stay bound is listed here.
      binds =
        mapAttrs (_: spawnBind) wmCfg.keybinds.spawn
        // mapAttrs (_: repeatBind) wmCfg.keybinds.spawn-repeat
        // {
          # ==== Focus ==== #
          "${bindCfg.switch-window-focus}" = "window-focus-next";
          "${bindCfg.move-window-focus.left}" = "window-focus-or-output-left";
          "${bindCfg.move-window-focus.right}" = "window-focus-or-output-right";
          "${bindCfg.move-window-focus.up}" = "window-focus-or-workspace-up";
          "${bindCfg.move-window-focus.down}" = "window-focus-or-workspace-down";
          "${bindCfg.move-monitor-focus.left}" = "output-focus-left";
          "${bindCfg.move-monitor-focus.right}" = "output-focus-right";
          "${bindCfg.move-workspace-focus.next}" = "workspace-next";
          "${bindCfg.move-workspace-focus.prev}" = "workspace-previous";

          # ==== Movement ==== #
          "${bindCfg.move-window.left}" = "column-move-left";
          "${bindCfg.move-window.right}" = "column-move-right";
          "${bindCfg.move-window.up}" = "window-move-or-workspace-up";
          "${bindCfg.move-window.down}" = "window-move-or-workspace-down";
          "${bindCfg.consume-window.left}" = "window-consume-left";
          "${bindCfg.consume-window.right}" = "window-consume-right";
          "${bindCfg.move-workspace.up}" = "workspace-move-up";
          "${bindCfg.move-workspace.down}" = "workspace-move-down";

          "Mod+WheelUp" = "workspace-previous";
          "Mod+WheelDown" = "workspace-next";
          "Mod+WheelLeft" = "window-focus-left";
          "Mod+WheelRight" = "window-focus-right";

          # ==== Windows ==== #
          "${bindCfg.center-window}" = "column-center";
          "${bindCfg.toggle-overview}" = {
            action = "overview-toggle";
            repeat = false;
          };
          "${bindCfg.close-window}" = {
            action = "window-close";
            repeat = false;
          };
          "${bindCfg.toggle-fullscreen}" = {
            action = "window-toggle-fullscreen";
            repeat = false;
          };
          "${bindCfg.maximize-to-window-edges}" = {
            action = "window-toggle-maximize-to-edges";
            repeat = false;
          };
          "${bindCfg.toggle-float}" = {
            action = "window-toggle-floating";
            repeat = false;
          };
          "${bindCfg.switch-focus-between-floating-and-tiling}" = {
            action = "window-focus-switch-floating";
            repeat = false;
          };
          "${bindCfg.minimize}" = {
            action = "window-minimize";
            repeat = false;
          };
          "${bindCfg.restore-minimize}" = {
            action = "window-restore-minimized";
            repeat = false;
          };
          "${bindCfg.toggle-scratchpad}" = {
            action = "scratchpad-toggle";
            repeat = false;
          };
          "${bindCfg.switch-layout}" = "workspace-set-layout toggle";

          # ==== Column extent ==== #
          "${bindCfg.switch-preset-column-width}" = "window-cycle-primary-extent";
          "${bindCfg.switch-preset-window-height}" = "window-cycle-secondary-extent";
          "${bindCfg.expand-column-to-available-width}" = "window-set-primary-extent 1.0";
          "${bindCfg.maximize-column}" = {
            action = "window-toggle-maximize";
            repeat = false;
          };
          "${bindCfg.reset-window-height}" = "window-set-secondary-extent 1.0";

          # ==== Umbriel-only ==== #
          "Mod+Shift+P" = {
            action = "window-toggle-pinned";
            repeat = false;
          };
          "Mod+Alt+Z" = {
            action = "window-move-to-scratchpad";
            repeat = false;
          };
          "Mod+Shift+Z" = {
            action = "window-restore-from-scratchpad";
            repeat = false;
          };
          "Mod+Shift+Tab" = {
            action = "window-focus-last";
            repeat = false;
          };
          "Mod+Ctrl+Shift+Left" = "window-move-to-output-previous";
          "Mod+Ctrl+Shift+Right" = "window-move-to-output-next";
          "Mod+Minus" = "window-modify-primary-extent -0.02";
          "Mod+Equal" = "window-modify-primary-extent 0.02";
          "Mod+Ctrl+Minus" = "window-modify-secondary-extent -0.02";
          "Mod+Ctrl+Equal" = "window-modify-secondary-extent 0.02";
          "Mod+Alt+1" = "workspace-set-layout scrolling";
          "Mod+Alt+2" = "workspace-set-layout dwindle";
          "Mod+Alt+3" = "workspace-set-layout master";

          # ==== Shell ==== #
          "${bindCfg.toggle-control-center}" = noctalia "panel-toggle control-center";
          "${bindCfg.toggle-launcher}" = noctalia "panel-toggle launcher";
          "${bindCfg.toggle-launcher-shortcuts}" = noctalia "plugin:custom-commands toggle";
          "${bindCfg.lock-screen}" = noctalia "session lock";
          "${bindCfg.clipboard-history}" = noctalia "panel-toggle clipboard";
          "${bindCfg.emoji}" = noctalia "panel-toggle launcher '/emo '";
          "${bindCfg.screen-recorder}" = noctalia "screenRecorder toggle";
          "${bindCfg.notification-center}" = noctalia "panel-toggle control-center notifications";
          "${bindCfg.toggle-dont-disturb}" = noctalia "notification-dnd-toggle";
          "${bindCfg.wallpaper-selector}" = noctalia "panel-toggle wallpaper";
          "${bindCfg.wallpaper-random}" = noctalia "wallpaper-random";
          "${bindCfg.windows-switcher}" = noctalia "panel-toggle launcher '/win '";

          # Umbriel has no screenshot action; noctalia owns capture.
          "${bindCfg.screenshot.area}" = noctalia "screenshot-region";
          "${bindCfg.screenshot.window}" = noctalia "screenshot-region";
          "${bindCfg.screenshot.screen}" = noctalia "screenshot-fullscreen pick";
          "${bindCfg.screenshot.edit}" = "spawn wl-paste --type image/png | satty --filename -";

          # ==== Help / mouse ==== #
          "Mod+Shift+slash" = {
            action = "cheatsheet-toggle";
            repeat = false;
          };
          "${bindCfg.mouse-mode.normal}" = "spawn pkill -x warpd; exec warpd --normal";
          "${bindCfg.mouse-mode.hint}" = "spawn pkill -x warpd; exec warpd --hint";
        }
        // listToAttrs (
          genList (i: {
            name = "${bindCfg.focus-workspace-prefix}+${toString (i + 1)}";
            value = "workspace-switch ${toString (i + 1)}";
          }) 9
        );

      settings = {
        include.optional.files = [
          "${config.home.homeDirectory}/.config/umbriel/noctalia.toml"
        ];
        include.files = [
          "${pkgs.umbriel}/share/umbriel/effects/animation/reveal/effect.toml"
          "${pkgs.umbriel}/share/umbriel/effects/animation/squash/effect.toml"
          "${pkgs.umbriel}/share/umbriel/effects/animation/workspace_wipe/effect.toml"
          "${pkgs.umbriel}/share/umbriel/effects/border/pulse/effect.toml"
          "${pkgs.umbriel}/share/umbriel/effects/border/audio/effect.toml"
          "${pkgs.umbriel}/share/umbriel/effects/window/scanlines/effect.toml"
          "${pkgs.umbriel}/share/umbriel/effects/screen/vignette/effect.toml"
          "${pkgs.umbriel}/share/umbriel/effects/cursor/glow/effect.toml"
          "${pkgs.umbriel}/share/umbriel/effects/cursor/trail/effect.toml"
        ];

        # Umbriel shows a keybind cheatsheet over the whole output on startup by default.
        general.show_cheatsheet = false;

        appearance = {
          prefer_no_csd = true;
          border_width = 4;
          outer_border_width = 0;
          corner_radius = wmCfg.border.radius;
          opaque_fullscreen = true;

          blur = {
            enabled = true;
            optimized = true;
            passes = 3;
            radius = 5;
            noise = 0.02;
            brightness = 0.9;
            contrast = 0.9;
            saturation = 1.5;
          };

          shadow = {
            enabled = true;
            softness = 10;
            offset_x = 2;
            offset_y = 2;
          };
        };

        input = {
          keyboard = {
            layout = "us";
            numlock_toggle = true;
          };
          focus.follows_mouse = true;
        };

        layout = {
          mode = "scrolling";
          gap = 16;
          extent_presets = [
            0.333
            0.5
            0.667
          ];
        };

        keybinds = binds;

        layer_rule = [
          {
            match.namespace = "^noctalia-bar-";
            blur = true;
            blur_ignore_alpha = 0.1;
          }
          {
            match.namespace = [
              "^noctalia-panel$"
              "^noctalia-attached-panel$"
              "^noctalia-notification$"
              "^noctalia-osd$"
            ];
            blur = true;
            blur_popups = true;
            blur_ignore_alpha = 0.1;
            blur_optimized = false;
          }
        ];

        window_rule = [
          # niri blurs every window, dialogs and popups included.
          {
            blur = true;
            blur_popups = true;
          }
          {
            match.app_id = [
              "^xdg-desktop-portal-gtk$"
              "^org.gnome.Nautilus$"
              "^org.gnome.Loupe$"
              "^com.gabm.satty$"
            ];
            default_floating = true;
          }
          {
            match = {
              app_id = "^dev.noctalia.Noctalia$";
              title = "^Noctalia Settings$";
            };
            default_floating = true;
            default_floating_size_px = {
              width = 1080;
              height = 920;
            };
          }
        ]
        ++ wmCfg.umbriel.window-rules;
      };
    in
    {
      options.wm.umbriel.window-rules = lib.mkOption {
        type = with lib.types; listOf (attrsOf anything);
        default = [ ];
        description = "Extra Umbriel [[window_rule]] entries.";
      };

      config.home.packages = [ warpdPatched ];

      config.xdg.configFile."umbriel/config.toml".source =
        (pkgs.formats.toml { }).generate "umbriel-config.toml"
          settings;
    };
}
