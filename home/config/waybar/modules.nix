{
  terminal,
  osConfig,
}:
let
  terminalRun = "${terminal} -e";
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
    ];
  };
  "custom/cava" = {
    exec = "~/.config/scripts/waybarCava.sh";
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
    tooltip-format = "{ifname} via {gwaddr} 󰊗";
    tooltip-format-wifi = "󰤢   {essid}:  {signalStrength}%";
    tooltip-format-ethernet = "{ifname} via {gwaddr} 󰊗";
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
    exec = "~/.config/scripts/wgStatus.sh";
    exec-if = "which wg-quick";
    on-click = "~/.config/scripts/wgStatus.sh toggle";
    tooltip = true;
    interval = 3;
    return-type = "json";
    escape = true;
  };
  "custom/gamemode" = {
    format = "{icon}";
    format-icons = {
      active = "󰊗";
      inactive = "󰺷";
    };
    exec = "~/.config/scripts/gamemodeStatus.sh";
    on-click = "~/.config/scripts/gamemodeStatus.sh toggle";
    tooltip = true;
    interval = 3;
    return-type = "json";
    escape = true;
  };
}
