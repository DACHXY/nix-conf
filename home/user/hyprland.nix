{
  pkgs,
  lib,
  inputs,
  system,
  hyprcursor-size,
  xcursor-size,
  nvidia-offload-enabled ? false,
  ...
}:
let
  terminal = "ghostty";
  startScript = import ./hypr/exec.nix {
    inherit
      pkgs
      lib
      inputs
      system
      terminal
      xcursor-size
      ;
  };
  mainMod = "SUPER";
  window = import ./hypr/window.nix;
  windowrule = import ./hypr/windowrule.nix;
  input = import ./hypr/input.nix;
  plugins = import ./hypr/plugin.nix;
  cursorName = "catppuccin-macchiato-lavender-cursors";

  getCurrentSong = pkgs.writeShellScriptBin "getSong" ''
    song_info=$(playerctl metadata --format '{{title}}  󰎆    {{artist}}')
    echo "$song_info"
  '';

  ewwWayland = pkgs.eww.overrideAttrs (oldAttrs: {
    cargoBuildFlags = [
      "--no-default-features"
      "--features=wayland"
      "--bin"
      "eww"
    ];
  });

in
{
  home.packages = with pkgs; [
    mpvpaper # Video Wallpaper
    yt-dlp
    hyprpaper
    hyprcursor
    ewwWayland
  ];

  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false;
    package = inputs.hyprland.packages.${system}.hyprland;

    plugins =
      (with inputs.hyprland-plugins.packages.${system}; [
        xtra-dispatchers
        hyprexpo
        hyprwinwrap
      ])
      ++ [
        inputs.hyprgrass.packages.${system}.default
      ];

    settings =
      {
        debug = {
          disable_logs = false;
        };
        bind = import ./hypr/bind.nix { inherit mainMod nvidia-offload-enabled; };
        bindm = import ./hypr/bindm.nix { inherit mainMod; };
        monitor = import ./hypr/monitor.nix;
        plugin = plugins;
        exec-once = ''${startScript}'';
        env = [
          ''HYPRCURSOR_THEME, ${cursorName}''
          ''HYPRCURSOR_SIZE, ${hyprcursor-size}''
          ''XCURSOR_THEME, ${cursorName}''
          ''XCURSOR_SIZE, ${xcursor-size}''
          ''XDG_CURRENT_DESKTOP, Hyprland''
          ''XDG_SESSION_DESKTOP, Hyprland''
          ''GDK_PIXBUF_MODULE_FILE, ${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache'' # Make rofi load svg
        ];
      }
      // window
      // windowrule
      // input;
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "~/.config/wallpapers/wall.png" ];
      wallpaper = [ ", ~/.config/wallpapers/wall.png" ];
      splash = false;
      ipc = "on";
    };
  };

  programs.hyprlock = {
    enable = true;
    importantPrefixes = [
      "$"
      "monitor"
      "size"
      "source"
    ];

    extraConfig =
      builtins.readFile ../config/hypr/hyprlock.conf
      + ''
        # CURRENT SONG
        label {
            monitor =
            text = cmd[update:1000] echo "$(${getCurrentSong}/bin/getSong)"
            color = rgba(235, 219, 178, .75)
            font_size = 16
            font_family = $font, $font2
            position = 0, 80
            halign = center
            valign = bottom
        }
      '';
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        ignore_systemd_inhibit = false;
      };

      listener = [
        # 2.5min -> set monitor backlight to minimum
        {
          timeout = 150;
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }
        # 2.5min -> turn off keyboard backlight
        {
          timeout = 150;
          on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
          on-resume = "brightnessctl -rd rgb:kbd_backlight";
        }
        # 5min -> Lock screen
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        # 5.5min -> Screen off
        {
          timeout = 330;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        # 30min -> Suspend pc
        # {
        #   timeout = 1800;
        #   on-timeout = "systemctl suspend";
        # }
      ];
    };
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = with pkgs; [
      rofi-emoji-wayland
      (rofi-calc.override { rofi-unwrapped = rofi-wayland-unwrapped; })
    ];
  };
}
