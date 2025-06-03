{
  pkgs,
  lib,
  inputs,
  config,
  system,
  osConfig,
  settings,
  ...
}:
let
  terminal = "ghostty";
  startScript = import ./hypr/exec.nix {
    inherit
      pkgs
      terminal
      ;
    xcursor-size = settings.hyprland.xcursor-size;
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
in
{
  home.packages = with pkgs; [
    mpvpaper # Video Wallpaper
    yt-dlp
    hyprcursor
  ];

  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    package = null;
    portalPackage = null;

    plugins =
      (with inputs.hyprland-plugins.packages.${system}; [
        xtra-dispatchers
        hyprwinwrap
      ])
      ++ [
        # inputs.hyprgrass.packages.${system}.default
        # inputs.hyprtasking.packages.${system}.hyprtasking
      ];

    settings =
      {
        debug = {
          disable_logs = true;
        };
        bind = import ./hypr/bind.nix {
          inherit mainMod;
          inherit pkgs;
          nvidia-offload-enabled = osConfig.hardware.nvidia.prime.offload.enableOffloadCmd;
        };
        bindm = import ./hypr/bindm.nix { inherit mainMod; };
        binde = import ./hypr/binde.nix { inherit mainMod; };
        monitor = import ./hypr/monitor.nix;
        plugin = plugins;
        exec-once = [ ''${startScript}'' ];
        env = [
          ''HYPRCURSOR_THEME, ${cursorName}''
          ''HYPRCURSOR_SIZE, ${builtins.toString settings.hyprland.cursor-size}''
          ''XCURSOR_THEME, ${cursorName}''
          ''XCURSOR_SIZE, ${builtins.toString settings.hyprland.xcursor-size}''
          ''XDG_CURRENT_DESKTOP, Hyprland''
          ''XDG_SESSION_DESKTOP, Hyprland''
          ''GDK_PIXBUF_MODULE_FILE, ${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache'' # Make rofi load svg
        ];
        workspace = import ./hypr/workspace.nix { monitors = settings.hyprland.monitors; };
      }
      // window
      // windowrule
      // input;
  };

  # === hyprpaper === #
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "~/.config/wallpapers/wall.png" ];
      wallpaper = [ ", ~/.config/wallpapers/wall.png" ];
      splash = false;
      ipc = "on";
    };
  };

  # === hyprlock === #
  programs.hyprlock = {
    enable = true;
    package = (
      pkgs.hyprlock.overrideAttrs (
        final: prev: {
          src = pkgs.fetchFromGitHub {
            owner = "hyprwm";
            repo = "hyprlock";
            rev = "da1d076d849fc0f298c1d287bddd04802bf7d0f9";
            hash = "sha256-IypoV7crmhQ4llD0n4qqO4XTRNAAbHfA+2oiTiq2qpk=";
          };
        }
      )
    );
    importantPrefixes = [
      "$"
      "monitor"
      "size"
      "source"
    ];

    settings =
      let
        font = "CaskaydiaCove Nerd Font";
        font2 = "SF Pro Display Bold";
        mainMonitor =
          if ((builtins.length settings.hyprland.monitors) > 0) then
            builtins.elemAt settings.hyprland.monitors 0
          else
            "";
      in
      {
        background = {
          monitor = "";
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        };

        # GENERAL
        general = {
          no_fade_in = false;
          grace = 0;
          disable_loading_bar = false;
          ignore_empty_input = true;
          fail_timeout = 1000;
        };

        # TIME
        label = [
          {
            monitor = "${mainMonitor}";
            text = ''cmd[update:1000] echo "$(date +"%-I:%M%p")"'';
            color = "rgba(250, 189, 47, .75)";
            font_size = 120;
            font_family = "${font2}";
            position = "0, -140";
            halign = "center";
            valign = "top";
          }

          # DAY-DATE-MONTH
          {
            monitor = "${mainMonitor}";
            text = ''cmd[update:1000] echo "<span>$(date '+%A, %d %B')</span>"'';
            color = "rgba(225, 225, 225, 0.75)";
            font_size = 30;
            font_family = "${font2}";
            position = "0, 200";
            halign = "center";
            valign = "center";
          }
          # USER
          {
            monitor = "${mainMonitor}";
            text = "Hello, $USER";
            color = "rgba(255, 255, 255, .65)";
            font_size = 25;
            font_family = "${font2}";
            position = "0, -70";
            halign = "center";
            valign = "center";
          }
          # Current Song
          {
            monitor = "${mainMonitor}";
            text = ''cmd[update:1000] echo "$(${getCurrentSong}/bin/getSong)"'';
            color = "rgba(235, 219, 178, .75)";
            font_size = 16;
            font_family = "${font}, ${font2}";
            position = "0, 80";
            halign = "center";
            valign = "bottom";
          }
        ];

        # LOGO
        image = {
          monitor = "${mainMonitor}";
          path = "$HOME/.face";
          border_size = 2;
          border_color = "rgba(255, 255, 255, .75)";
          size = 95;
          rounding = -1;
          rotate = 0;
          reload_time = -1;
          reload_cmd = "";
          position = "0, 60";
          halign = "center";
          valign = "center";
        };

        # INPUT FIELD
        input-field = [
          {
            monitor = "${mainMonitor}";
            size = "290, 60";
            outline_thickness = 2;
            dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.2; # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = true;
            outer_color = "rgba(0, 0, 0, 0)";
            inner_color = "rgba(60, 56, 54, 0.35)";
            font_color = "rgb(200, 200, 200)";
            fail_color = "rgba(218, 53, 50, 0.56)";
            fade_on_empty = false;
            font_family = "${font2}";
            placeholder_text = ''<i><span foreground="##ffffff99">Bruh, come back!</span></i>'';
            hide_input = false;
            position = "0, -140";
            halign = "center";
            valign = "center";
          }
        ];

      };
  };

  # === hypridle === #
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

  # === hyprsunset === #
  systemd.user.services.hyprsunset = {
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Unit = {
      ConditionEnvironment = "WAYLAND_DISPLAY";
      Description = "Blue light filter";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hyprsunset}/bin/hyprsunset -t 3000k";
      Restart = "always";
      RestartSec = 2;
    };
  };

  # === waybar === #
  programs.waybar = {
    enable = true;
    style = ../../home/config/waybar/style.css;
    settings = import ../../home/config/waybar/config.nix { inherit terminal osConfig; };
    systemd = {
      enable = true;
    };
  };

  # === swaync === #
  services.swaync = {
    enable = true;
    settings = {
      control-center-height = 900;
      control-center-margin-bottom = 20;
      control-center-margin-left = 20;
      control-center-margin-right = 20;
      control-center-margin-top = 20;
      control-center-width = 500;
      fit-to-screen = false;
      hide-on-action = true;
      hide-on-clear = true;
      image-visibility = "when-available";
      keyboard-shortcuts = true;
      layer = "overlay";
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      notification-icon-size = 64;
      notification-window-width = 490;
      positionX = "right";
      positionY = "top";
      script-fail-notify = true;
      timeout = 3;
      timeout-critical = 0;
      timeout-low = 2;
      transition-time = 200;
      widgets = lib.mkForce [
        "title"
        "notifications"
        "mpris"
      ];
    };
    style = # css
      ''
        @define-color bgc rgba(0, 0, 0, 0.1);
        @define-color borderc #ebdbb2;
        @define-color textc #282828;

        * {
          font-family: JetBrainsMonoNerdFontMono;
          font-weight: bold;
          font-size: 15px;
          border-width: 3px;
          border-color: #ebdbb2;
        }

        .control-center .notification-row:focus,
        .control-center .notification-row:hover {
          opacity: 1;
          background: @bgc;
        }

        .notification-row {
          outline: none;
          margin: 20px;
          padding: 0;
        }

        .notification {
          background: @textc;
          margin: 0px;
          border-radius: 6px;
          border-width: 3px;
          border-color: #ebdbb2;
        }

        .notification-content {
          background: @textc;
          padding: 7px;
          margin: 0;
        }

        .close-button {
          background: @textc;
          color: @borderc;
          text-shadow: none;
          padding: 0;
          border-radius: 20px;
          margin-top: 9px;
          margin-right: 5px;
        }

        .close-button:hover {
          box-shadow: none;
          background: @borderc;
          color: @textc;
          transition: all .15s ease-in-out;
          border: none;
        }

        .notification-action {
          color: @bgc;
          background: @textc;
        }

        .summary {
          padding-top: 7px;
          font-size: 13px;
          color: @borderc;
        }

        .time {
          font-size: 11px;
          color: @borderc;
          margin-right: 40px;
        }

        .body {
          font-size: 12px;
          color: @borderc;
        }

        .control-center {
          background-color: @bgc;
          border-radius: 20px;
        }

        .control-center-list {
          background: transparent;
        }

        .control-center-list-placeholder {
          opacity: .5;
        }

        .floating-notifications {
          background: transparent;
        }

        .blank-window {
          background: alpha(black, 0.1);
        }

        .widget-title {
          color: @borderc;
          padding: 10px 10px;
          margin: 10px 10px 5px 10px;
          font-size: 1.5rem;
        }

        .widget-title>button {
          font-size: 1rem;
          color: @borderc;
          padding: 10px;
          text-shadow: none;
          background: @bgc;
          box-shadow: none;
          border-radius: 5px;
        }

        .widget-title>button:hover {
          background: @borderc;
          color: #282828;
        }

        .widget-label {
          margin: 10px 10px 10px 10px;
        }

        .widget-label>label {
          font-size: 1rem;
          color: @textc;
        }

        .widget-mpris {
          color: @borderc;
          padding: 5px 5px 5px 5px;
          margin: 10px;
          border-radius: 20px;
        }

        .widget-mpris>box>button {
          border-radius: 20px;
        }

        .widget-mpris-player {
          padding: 5px 5px;
          margin: 10px;
        }
      '';
  };

  systemd.user.services.swaync.Service = {
    ExecStart = lib.mkForce ''${pkgs.swaynotificationcenter}/bin/swaync --config ${
      config.xdg.configFile."swaync/config.json".target
    } --style ${config.xdg.configFile."swaync/style.css".target}'';
    Environment = [
      "XDG_CONFIG_HOME=/home/_dummy"
    ];
  };

  # === rofi === #
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = with pkgs; [
      rofi-emoji-wayland
      (rofi-calc.override { rofi-unwrapped = rofi-wayland-unwrapped; })
    ];
  };
}
