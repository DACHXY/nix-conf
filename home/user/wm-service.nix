{
  osConfig,
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) escapeShellArgs mkForce getExe';
  inherit (osConfig.systemConf) username;
  inherit (pkgs.stdenv.hostPlatform) system;

  getCurrentSong = pkgs.writeShellScript "getSong" ''
    song_info=$(playerctl metadata --format '{{title}}  󰎆    {{artist}}')
       echo "$song_info"
  '';
in
{
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GDK_BACKEND = "wayland";

    QT_SCALE_FACTOR = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_IM_MODULES = "wayland;fcitx;ibus";

    MOZ_ENABLE_WAYLAND = "1";
    SDL_VIDEODRIVER = "wayland";
    WLR_NO_HARDWARE_CURSORS = "1";
    CLUTTER_BACKEND = "wayland";
    EGL_PLATFORM = "wayland";
    XDG_SESSION_TYPE = "wayland";
  };

  home.packages = with pkgs; [
    mpvpaper # Video Wallpaper
    libnotify
    sunsetr

    wlogout
    wl-clipboard

    # Util
    grim
    slurp
  ];

  systemd.user.tmpfiles.rules = [
    "d ${config.home.homeDirectory}/Pictures/Wallpapers 0744 ${username} users -"
  ];

  # === kanshi (Monitor Manager) === #
  services.kanshi.enable = true;

  # === Awww === #
  services.swww = {
    enable = true;
    package = inputs.awww.packages.${system}.awww;
  };

  systemd.user.services.swww.Service.ExecStart =
    mkForce "${getExe' config.services.swww.package "awww-daemon"} ${escapeShellArgs config.services.swww.extraArgs}";

  # === sunsetr === #
  services.sunsetr.enable = true;

  # === swaync === #
  services.swaync = {
    enable = true;
    package = (
      pkgs.swaynotificationcenter.overrideAttrs (prev: rec {
        version = "0.12.1";

        buildInputs =
          prev.buildInputs
          ++ (with pkgs; [
            libhandy
            pantheon.granite
            gtk-layer-shell
          ]);

        src = pkgs.fetchFromGitHub {
          owner = "ErikReider";
          repo = "SwayNotificationCenter";
          rev = "v${version}";
          hash = "sha256-kRawYbBLVx0ie4t7tChkA8QJShS83fUcGrJSKkxBy8Q=";
        };
      })
    );
    settings = {
      control-center-height = 900;
      control-center-margin-bottom = 20;
      control-center-margin-left = 20;
      control-center-margin-right = 20;
      control-center-margin-top = 20;
      control-center-width = 500;
      fit-to-screen = true;
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
        @define-color textc #212121;

        * {
          font-family: ${osConfig.stylix.fonts.sansSerif.name};
          font-size: ${toString osConfig.stylix.fonts.sizes.desktop}px;
          font-weight: bold;
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
          margin: 5px;
          padding: 0;
        }

        .notification {
          background: @bgc;
          margin: 0px;
          border-radius: 6px;
          border-width: 3px;
          border-color: @borderc;
        }

        .notification-content {
          background: @bgc;
          padding: 7px;
          margin: 0;
        }

        .close-button {
          background: @bgc;
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
          color: @borderc;
          background: @bgc;
        }

        .notification-action:hover {
          color: @textc;
          background: @borderc;
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
          color: @textc;
        }

        .widget-label {
          margin: 10px 10px 10px 10px;
        }

        .widget-label>label {
          font-size: 1rem;
          color: @borderc;
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

  # === rofi === #
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    plugins = with pkgs; [
      rofi-emoji
      rofi-calc
    ];
  };

  # === hyprlock === #
  programs.hyprlock = {
    enable = true;
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
      in
      {
        background = [
          {
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
            contrast = 0.8916;
            brightness = 0.8172;
            vibrancy = 0.1696;
            vibrancy_darkness = 0.0;
          }
        ];

        animations = {
          enabled = true;
          fade_in = {
            duration = 300;
            bezier = "easeeOutQuint";
          };
          fade_out = {
            duration = 300;
            bezier = "easeeOutQuint";
          };
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
            text = ''cmd[update:1000] echo "$(${getCurrentSong})"'';
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
        after_sleep_cmd = "niri msg power-off-monitors";
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
          on-timeout = "niri msg power-off-monitors";
          on-resume = "niri msg power-on-monitors";
        }
        # 30min -> Suspend pc
        # {
        #   timeout = 1800;
        #   on-timeout = "systemctl suspend";
        # }
      ];
    };
  };
}
