{
  terminal,
  osConfig,
  wallRand,
}:
let
  modulesConfig = import ./modules.nix { inherit terminal osConfig wallRand; };
in
map (dev: dev // modulesConfig) [
  # Monitor 1
  {
    output = "DP-2";
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
    modules-left = [
      "custom/os"
      "hyprland/workspaces"
      "clock"
      "custom/cava"
      "mpris"
    ];
    modules-center = [
      "hyprland/window"
    ];
    modules-right = (
      [
        "wlr/taskbar"
      ]
      ++ (
        if osConfig.programs.gamemode.enable then
          [
            "custom/gamemode"
          ]
        else
          [ ]
      )
      ++ [
        "custom/wallRand"
        "custom/wireguard"
        "idle_inhibitor"
        "network"
        "cpu"
        "memory"
        "pulseaudio"
        "custom/swaync"
      ]
    );
  }
  # Monitor 2
  {
    output = "DP-3";
    layer = "top";
    exclusive = true;
    height = 54;
    passthrough = false;
    position = "top";
    fixed-center = true;
    ipc = true;
    margin-top = 0;
    margin-left = 0;
    margin-right = 0;
    margin-bottom = 0;
    modules-left = [
      "clock"
      "mpris"
    ];
    modules-center = [
      "hyprland/window"
    ];
    modules-right = [
      "wlr/taskbar"
      "temperature"
      "cpu"
      "memory"
      "pulseaudio"
    ];
  }
  # Lap
  {
    output = "eDP-1";
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
    modules-left = [
      "custom/os"
      "hyprland/workspaces"
      "clock"
      "mpris"
    ];
    modules-center = [
      "hyprland/window"
    ];
    modules-right = [
      "wlr/taskbar"
      "temperature"
      "custom/wireguard"
      "idle_inhibitor"
      "network"
      "pulseaudio"
      "battery"
      "custom/swaync"
    ];
  }
  # Other
  {
    output = [
      "!eDP-1"
      "!DP-1"
      "!DP-3"
    ];
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
    modules-left = [
      "custom/os"
      "hyprland/workspaces"
      "clock"
      "mpris"
      "custom/cava"
    ];
    modules-center = [
      "hyprland/window"
    ];
    modules-right = [
      "wlr/taskbar"
      "temperature"
      "custom/wireguard"
      "idle_inhibitor"
      "network"
      "cpu"
      "memory"
      "pulseaudio"
      "battery"
      "custom/swaync"
    ];
  }
]
