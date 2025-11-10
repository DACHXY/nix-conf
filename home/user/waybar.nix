{
  settings ? [ ],
}:
{
  osConfig,
  config,
  username,
  lib,
  pkgs,
  helper,
  ...
}:
let
  inherit (helper) mkToggleScript;
  inherit (lib) optionalString;

  gamemodeToggle = mkToggleScript {
    service = "gamemodedr";
    start = "on";
    stop = "off";
    icon = "";
    notify-icon = "preferences-desktop-gaming";
    extra = {
      text = "$(pgrep -c gamemode)";
      tooltip = "Running: $(systemctl --user is-active gamemodedr)";
    };
  };

  airplayToggle = mkToggleScript {
    service = "uxplay";
    start = "on";
    stop = "off";
    icon = "󱖑";
  };

  wgToggle = pkgs.writeShellScript "wg-toggle" ''
    INTERFACE="wg0"

    if [ "$1" = "toggle" ]; then
      if ip link show "$INTERFACE" >/dev/null 2>&1; then
        pkexec systemctl stop wg-quick-wg0.service
      else
        pkexec systemctl start wg-quick-wg0.service
      fi
      exit 0
    fi

    if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
      echo "{\"text\": \"Not Connected\", \"tooltip\": \"WireGuard is down\", \"alt\": \"disconnected\", \"class\": \"disconnected\"}"
      exit 0
    fi

    echo "{\"text\": \"Connected\", \"tooltip\": \"WireGuard connected\", \"alt\": \"connected\", \"class\": \"connected\"}"
    exit 0
  '';

  mkWall = import ../scripts/mkWall.nix { inherit config pkgs; };
  rofiWall = import ../scripts/rofiwall.nix { inherit config pkgs; };

  # Change Wallpaper
  wallRand = pkgs.writeShellScript "wallRand" ''
    WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
    mapfile -t wallpapers < <(find "$WALLPAPER_DIR" -type f)

    count="''${#wallpapers[@]}"

    random_index=$(( RANDOM % count ))
    selected="''${wallpapers[$random_index]}"

    if [ ! -f "$selected" ]; then
      echo "File not exist: $selected"
      exit 1
    fi

    ${config.services.swww.package}/bin/swww img "$selected" --transition-fps 45 --transition-duration 1 --transition-type random
  '';

  rbwSelector = import ../scripts/rbwSelector.nix { inherit pkgs; };

  toggleRecord = pkgs.callPackage ../scripts/record.nix { };
in
{
  home.packages = [
    mkWall
  ];

  # For wallpapers
  systemd.user.tmpfiles.rules = [
    "d /tmp/wall_cache 700 ${username} -"
  ];

  # === gamemoded -r === #
  systemd.user.services.gamemodedr = lib.mkIf osConfig.programs.gamemode.enable {
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.gamemode}/bin/gamemoded -r";
    };
  };

  # === waybar === #
  systemd.user.services.waybar = lib.mkIf config.programs.waybar.enable {
    Unit = {
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
  };

  programs.waybar =
    let
      color = "#ebdbb2";
    in
    {
      enable = true;
      style =
        let
          borderRadius = "6px";
          border = "1px solid @fg-bg";
          gap = "4px";
        in
        lib.mkForce
          # css
          ''
            @define-color main ${color};
            @define-color bg-bg rgba(0, 0, 0, 0);
            @define-color fg-bg alpha(#fff, 0.05);

            * {
              font-family: ${osConfig.stylix.fonts.sansSerif.name};
              min-height: 0;
              font-size: ${toString (osConfig.stylix.fonts.sizes.desktop + 4)}px;
              font-feature-settings: '"zero", "ss01", "ss02", "ss03", "ss04", "ss05", "cv31"';
              transition-property: all;
              transition-duration: 0.3s;
            }

            #clock,
            #mpris,
            #window,
            #memory,
            #cpu,
            #pulseaudio {
              font-size: ${toString (osConfig.stylix.fonts.sizes.desktop)}px;
            }

            /* Main bar */
            window#waybar {
              background-color: @bg-bg;
            }

            window#waybar > .horizontal {
              padding: ${gap};
            }

            window#waybar.hidden {
              opacity: 0.5;
            }

            /* Set transparent if empty */
            window#waybar .empty {
              background-color: transparent;
              border-color: transparent;
            }

            /* tooltip */
            tooltip {
              background-color: @fg-bg;
              border: ${border};
              border-radius: ${borderRadius};
            }

            tooltip label {
              padding: 4px 10px;
              color: @main;
            }

            box.module, label.module {
              background: @fg-bg;
              color: @main;
              border-radius: ${borderRadius};
              border: ${border};
              padding: 0px 12px;
            }

            box.module button:hover {
              background: shade(@fg-bg, 1.5);
            }

            label:hover {
              background: shade(@fg-bg, 1.5);
            }

            .modules-left .module {
              margin-right: ${gap};
            }

            .modules-right .module {
              margin-left: ${gap};
            }

            .modules-center .module {
              background: transparent;
              border-color: transparent;
            }

            /* Workspaces */
            #workspaces {
              padding-left: 2px;
              padding-right: 2px;
            }

            #workspaces button {
              border-radius: 16px;
              padding: 0px 6px;
            }

            /* Taskbar */
            #taskbar {
              background: transparent;
              border-color: transparent;
            }

            /* Group */
            #cpu {
              border-top-right-radius: 0;
              border-bottom-right-radius: 0;
              padding-right: 0;
              border-right: none;
            }
            #memory {
              border-top-left-radius: 0;
              border-bottom-left-radius: 0;
              margin-left: 0;
              border-left: none;
            }

            #temperature.critical {
              background-color: red;
            }

            #battery.good {
              color: #ebdbb2;
            }

            #battery.warning {
              color: #eed49f;
            }

            #battery.critical {
              color: #ee99a0;
            }

            #battery.charging,
            #battery.plugged {
              color: #a6da95;
            }
          '';

      settings =
        let
          commonConfig = {
            layer = "top";
            exclusive = true;
            passthrough = false;
            position = "top";
            fixed-center = true;
            ipc = true;
            margin-top = 0;
            margin-left = 0;
            margin-right = 0;
            margin-bottom = 0;

            modules-center = [
              "hyprland/window"
            ];
          };

          modulesConfig =
            let
              terminalRun = "${config.programs.ghostty.package}/bin/ghostty -e";
            in
            {
              "hyprland/workspaces" = {
                active-only = false;
                all-outputs = true;
                format = "{icon}";
                show-special = false;
                on-click = "activate";
                on-scroll-up = "hyprctl dispatch workspace e+1";
                on-scroll-down = "hyprctl dispatch workspace e-1";
                persistent-workspaces = {
                  "1" = [ ];
                  "2" = [ ];
                  "3" = [ ];
                  "4" = [ ];
                };
                format-icons = {
                  active = "";
                  default = "";
                };
              };
              clock = {
                format = "<b>󰥔 {:%H:%M 󰃭 %d/%m}</b>";
                tooltip-format = "{:%A %d %B %Y}";
              };
              actions = {
                on-click-right = "mode";
                on-click-forward = "tz_up";
                on-click-backward = "tz_down";
                on-scroll-up = "shift_up";
                on-scroll-down = "shift_down";
              };
              "custom/os" = {
                format = "󱄅";
                on-click = "wlogout --protocol layer-shell";
              };
              cpu = {
                format = " {usage}%";
                max-length = 20;
                interval = 5;
                on-click-right = "${terminalRun} btop";
              };
              "hyprland/window" = {
                format = "{}";
                max-length = 40;
                separate-outputs = true;
                offscreen-css = true;
                offscreen-css-text = "(inactive)";
                rewrite = {
                  "nvim . (.*)" = "  $1";
                  "(.*) - Visual Studio Code" = "  $1";
                  "\\(\\d+\\) Discord (.*)" = "  $1";

                  # Firefox
                  "(.*) - YouTube — Mozilla Firefox" = "  $1";
                  "(.*)\\.pdf — Mozilla Firefox" = "  $1";
                  "(.*) — Mozilla Firefox" = "  $1";
                  "(.*) - YouTube Music — Mozilla Firefox" = "󰎆  $1";

                  # Firefox Nightly
                  "(.*) - YouTube — Firefox Nightly" = "  $1";
                  "(.*)\\.pdf — Firefox Nightly" = "  $1";
                  "(.*) — Firefox Nightly" = "  $1";
                  "(.*) - YouTube Music — Firefox Nightly" = "󰎆  $1";

                  # Zen
                  "(.*) - YouTube — Zen Browser" = "  $1";
                  "(.*) - YouTube Music — Zen Browser" = "󰎆  $1";
                  "(.*) — Zen Browser" = " $1";

                  "(.*) - VLC media player" = "  $1";
                };
              };
              memory = {
                interval = 30;
                format = " {used:0.1f}GB/{total:0.1f}G";
                format-alt-click = "click";
                tooltip = true;
                tooltip-format = "{used:0.1f}GB/{total:0.1f}G";
                on-click-right = "${terminalRun} btop";
              };
              mpris = {
                interval = 10;
                format = " {status_icon} <i>{title} | {artist} </i>";
                format-paused = " {status_icon} <i>{title} | {artist} </i>";
                on-click = "playerctl play-pause";
                on-click-right = "playerctl next";
                scroll-step = 5.0;
                smooth-scrolling-threshold = 1;
                status-icons = {
                  paused = "󰐎";
                  playing = "󰎇";
                  stopped = "";
                };
                max-length = 30;
              };
              pulseaudio = {
                format = "{icon} {volume}%";
                format-bluetooth = "󰂰 {volume}%";
                format-muted = " Muted";
                format-icons = {
                  default = [
                    ""
                    ""
                    " "
                    " "
                  ];
                  ignored-sinks = [
                    "Easy Effects Sink"
                  ];
                };
                scroll-step = 5.0;
                on-click = "pavucontrol -t 3";
                tooltip-format = "{icon} {desc} | {volume}%";
                smooth-scrolling-threshold = 1;
              };
              temperature = {
                interval = 10;
                tooltip = true;
                hwmon-path = [
                  "/sys/class/hwmon/hwmon1/temp1_input"
                  "/sys/class/thermal/thermal_zone0/temp"
                ];
                critical-threshold = 82;
                format-critical = " {temperatureC}°C";
                format = "{icon} {temperatureC}°C";
                format-icons = [
                  ""
                  ""
                  ""
                  ""
                ];
                on-click-right = "kitty -c ~/.config/kitty/kitty.conf --title btop sh -c 'btop'";
              };
              "custom/swaync" = {
                tooltip = true;
                format = "{icon}";
                format-icons = {
                  notification = "󱅫";
                  none = "󰂚";
                  dnd-notification = "󱏧<span foreground='red'><sup></sup></span>";
                  dnd-none = "󱏧";
                  inhibited-notification = "󰂚<span foreground='red'><sup></sup></span>";
                  inhibited-none = "󰂚";
                  dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
                  dnd-inhibited-none = "󱏧";
                };
                return-type = "json";
                exec-if = "which swaync-client";
                exec = "swaync-client -swb";
                on-click = "sleep 0.1 && swaync-client -t -sw";
                on-click-right = "swaync-client -d -sw";
                escape = true;
              };
              "wlr/taskbar" = {
                format = " {icon} ";
                icon-size = 20;
                all-outputs = false;
                tooltip-format = "{title}";
                on-click = "activate";
                on-click-middle = "close";
                ignore-list = [
                  "rofi"
                  "chromium-browser"
                  "firefox"
                  "firefox-nightly"
                  "zen"
                  "kitty"
                  "jetbrains-studio"
                  "Brave-browser"
                  "Spotify"
                  "nemo"
                  "vlc"
                  "com.mitchellh.ghostty"
                  "code"
                  ".virt-manager-wrapped"
                  "virt-manager"
                  "steam_app_*"
                  "obsidian"
                ];
              };
              "custom/cava" = {
                exec = "${pkgs.writeShellScript "cava-wave" ''
                  #Taken from JaKoolit's dotfiles

                  bar="▁▂▃▄▅▆▇█"
                  dict="s/;//g"

                  bar_length=''\${#bar}

                  for ((i = 0; i < bar_length; i++)); do
                    dict+=";s/$i/''\${bar:$i:1}/g"
                  done

                  config_file="/tmp/bar_cava_config"
                  cat >"$config_file" <<EOF
                  [general]
                  bars = 10

                  [input]
                  method = pulse
                  source = auto

                  [output]
                  method = raw
                  raw_target = /dev/stdout
                  data_format = ascii
                  channels = mono
                  ascii_max_range = 7
                  EOF

                  pkill -f "cava -p $config_file"

                  cava -p "$config_file" | sed -u "$dict"
                ''}";
                format = "{}";
                on-click = "${terminalRun} cava";
              };
              battery =
                let
                  fullAt = if osConfig.services.tlp.enable then 80 else 96;
                in
                {
                  full-at = fullAt;
                  states = {
                    good = fullAt;
                    warning = 30;
                    critical = 15;
                  };
                  format = "{icon} {capacity}%";
                  format-icons = [
                    "󰂎"
                    "󰁺"
                    "󰁻"
                    "󰁼"
                    "󰁽"
                    "󰁾"
                    "󰁿"
                    "󰂀"
                    "󰂁"
                    "󰂂"
                    "󰁹"
                  ];
                  format-charging = "󰂄 {capacity}%";
                  format-plugged = "󰂄 {capacity}%";
                  format-alt = "{icon} {time}";
                };
              network = {
                format = "{ifname}";
                format-wifi = "󰤨";
                format-ethernet = "󰈀";
                format-disconnected = "󰤭";
                tooltip-format = "{ifname} via {gwaddr}";
                tooltip-format-wifi = "󰤢   {essid}:  {signalStrength}%";
                tooltip-format-ethernet = "{ifname} via {gwaddr}";
                tooltip-format-disconnected = "Disconnected";
                max-length = 50;
                interval = 5;
                on-click = "~/.config/scripts/rofiWifi.sh";
              };
              idle_inhibitor = {
                format = "{icon}";
                format-icons = {
                  activated = "󰅶";
                  deactivated = "󰾫";
                };
              };
              "custom/wireguard" = {
                format = "{icon}";
                format-icons = {
                  connected = "󰒘";
                  disconnected = "";
                };
                exec = "${wgToggle}";
                exec-if = "which wg-quick";
                on-click = "${wgToggle} toggle";
                tooltip = true;
                interval = 3;
                return-type = "json";
                escape = true;
              };
              "custom/gamemode" = {
                format-icons = {
                  on = "󰊗";
                  off = "󰺷";
                };
                format = "{icon}<span foreground='${color}'><sub>{text}</sub></span>";
                exec = "${gamemodeToggle}";
                interval = 3;
                tooltip = true;
                return-type = "json";
                escape = true;
                on-click = "${gamemodeToggle} toggle";
              };
              "custom/wallRand" = {
                format = "";
                on-click = "${rofiWall}";
                on-click-right = "${wallRand}";
              };
              "custom/airplay" = {
                format = "{icon}";
                format-icons = {
                  on = "󱖑";
                  off = "";
                };
                exec = "${airplayToggle}";
                interval = 3;
                tooltip = true;
                return-type = "json";
                escape = true;
                on-click = "${airplayToggle} toggle";
              };
              "custom/bitwarden" = {
                format = "󰯄";
                on-click = "${rbwSelector}";
              };
              "custom/recording" = {
                format = "{icon}";
                format-icons = {
                  on = "󰑋";
                  off = "";
                };
                exec = "${toggleRecord}";
                interval = 1;
                on-click = "${toggleRecord} toggle";
              };
            };

          otherConfig = {
            modules-left = [
              "custom/os"
              "hyprland/workspaces"
              "clock"
              "mpris"
              "custom/cava"
            ];
            modules-right = [
              "wlr/taskbar"
              (optionalString osConfig.programs.gamemode.enable "custom/gamemode")
              "temperature"
              "custom/recording"
              "idle_inhibitor"
              "network"
              "cpu"
              "memory"
              "pulseaudio"
              "battery"
              "custom/swaync"
            ];
          };

          finalList = if ((builtins.length settings) == 0) then [ otherConfig ] else settings;
        in
        map (dev: dev // modulesConfig // commonConfig) finalList;

      systemd = {
        enable = true;
        target = "graphical-session.target";
      };
    };
}
