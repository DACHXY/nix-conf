{
  osConfig,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) system;

  wmCfg = config.wm;
  bindCfg = wmCfg.keybinds;
  mainMod = bindCfg.mod;
in
{
  config = mkIf osConfig.programs.hyprland.enable {
    wm = {
      exec-once = /* bash */ ''
        dbus-update-activation-environment --systemd HYPRLAND_INSTANCE_SIGNATURE
      '';
      keybinds = {
        mod = "SUPER";
        separator = ",";
        hypr-type = true;
      };
    };

    home.packages = with pkgs; [
      hyprcursor
    ];

    imports = [
      (import ./hypr/bind.nix { inherit mainMod; })
      ./hypr/workspace.nix
      ./hypr/window.nix
      ./hypr/windowrule.nix
      ./hypr/input.nix
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      systemd = {
        enable = true;
        variables = [ "--all" ];
      };
      package = null;
      portalPackage = null;

      plugins = (
        with inputs.hyprland-plugins.packages.${system};
        [
          hyprwinwrap
        ]
      );

      settings = {
        "$mainMod" = mainMod;

        debug = {
          disable_logs = true;
        };

        ecosystem.no_update_news = true;

        bindm = [
          # Move/resize windows with mainMod + LMB/RMB and dragging
          "${mainMod}, mouse:272, movewindow"
          "${mainMod}, mouse:273, resizewindow"
        ];

        binde =
          let
            resizeStep = toString 20;
            brightnessStep = toString 10;
            volumeStep = toString 4;
          in
          [
            ",XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_SINK@ 0 && wpctl set-volume @DEFAULT_SINK@ ${volumeStep}%+"
            ",XF86AudioLowerVolume, exec, wpctl set-mute @DEFAULT_SINK@ 0 && wpctl set-volume @DEFAULT_SINK@ ${volumeStep}%-"
            ",XF86MonBrightnessDown, exec, brightnessctl set ${brightnessStep}%-"
            ",XF86MonBrightnessUp, exec, brightnessctl set ${brightnessStep}%+"
            "${mainMod} CTRL, l, resizeactive, ${resizeStep} 0"
            "${mainMod} CTRL, h, resizeactive, -${resizeStep} 0"
            "${mainMod} CTRL, k, resizeactive, 0 -${resizeStep}"
            "${mainMod} CTRL, j, resizeactive, 0 ${resizeStep}"
          ];

        plugin = {
          hyprwinrap = {
            class = "kitty-bg";
          };

          touch_gestures = {
            sensitivity = 4.0;
            workspace_swipe_fingers = 3;
            workspace_swipe_edge = "d";
            long_press_delay = 400;
            resize_on_border_long_press = true;
            edge_margin = 10;
            emulate_touchpad_swipe = false;
          };
        };

        exec-once = [ "${wmCfg.exec-once}" ];

        env = [
          "XDG_CURRENT_DESKTOP, Hyprland"
          "XDG_SESSION_DESKTOP, Hyprland"
          "GDK_PIXBUF_MODULE_FILE, ${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
        ];

        misc = {
          disable_hyprland_logo = true;
          force_default_wallpaper = 0;
          disable_splash_rendering = true;
        };
      };
    };
  };
}
