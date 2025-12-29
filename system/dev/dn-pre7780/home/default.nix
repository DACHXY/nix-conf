{
  config,
  lib,
  helper,
  ...
}:
let
  inherit (helper) getMonitors;
  inherit (builtins) elemAt;
  inherit (config.networking) hostName;
  inherit (config.systemConf) username;
  inherit (lib) optionalString mkForce;

  wmName = if config.programs.hyprland.enable then "hyprland" else "niri";
in
{
  home-manager.users."${username}" =
    {
      osConfig,
      config,
      pkgs,
      ...
    }:
    let
      monitors = getMonitors hostName config;
      mainMonitor = (elemAt monitors 0).criteria;
      secondMonitor = (elemAt monitors 1).criteria;
      mainMonitorSwayFormat = "desc:ASUSTek COMPUTER INC - ASUS VG32VQ1B";
    in
    {
      home.packages = with pkgs; [
        mattermost-desktop
      ];

      # NOTE: Disable idle
      services.hypridle.enable = mkForce false;

      # hyprlock shows on main monitor
      programs.hyprlock.monitors = [
        mainMonitorSwayFormat
      ];

      services.kanshi.settings = [
        {
          profile.name = "${hostName}";
          profile.outputs = [
            {
              criteria = "ASUSTek COMPUTER INC ASUS VG32VQ1B 0x00002271";
              mode = "2560x1440@164.554001Hz";
              position = "0,0";
              scale = 1.0;
            }
            {
              criteria = "Acer Technologies XV272U V3 1322131231233";
              mode = "2560x1440@179.876999Hz";
              position = "-1440,-600";
              transform = "90";
            }
          ];
        }
      ];

      programs.ghostty.settings = {
        background-opacity = 0.9;
      };

      # ==== Shells ==== #
      # Caelestia
      programs.caelestia.settings = {
        osd = {
          enableBrightness = false;
          enableMicrophone = true;
        };
      };

      # Noctalia
      programs.noctalia-shell.filteredIds = [
        "Brightness"
      ];

      # ==== WM ==== #
      programs.niri.settings = {
        binds = with config.lib.niri.actions; {
          "Mod+G".action = focus-workspace "game";
          "Mod+Shift+G".action.move-column-to-workspace = [ "game" ];

          # Overrides
          "Mod+B".action = mkForce (focus-workspace "browser");
          "Mod+Shift+B".action.move-column-to-workspace = [ "browser" ];
        };

        hotkey-overlay = {
          hide-not-bound = true;
          skip-at-startup = true;
        };

        workspaces."browser" = {
          open-on-output = secondMonitor;
        };

        # Other settings are located in `public/dn/common.nix`
        workspaces."game" = {
          open-on-output = mainMonitor;
        };

        window-rules = [
          # Second Monitor App
          {
            matches = [
              {
                app-id = "^discord$";
              }
              {
                app-id = "^thunderbird$";
              }
            ];

            open-on-output = secondMonitor;
          }
        ];
      };

      imports = [
        ../../../../home/presets/basic.nix
        ../../../../home/user/zellij.nix
        ./expr
        ./wm

        # Bitwarden client
        (import ../../../../home/user/bitwarden.nix {
          email = "danny@net.dn";
          baseUrl = "https://bitwarden.net.dn";
        })

        # waybar
        (import ../../../../home/user/waybar.nix {
          matchByDesc = true;
          settings = [
            # monitor 1
            {
              output = "${(builtins.elemAt monitors 0).criteria}";
              height = 48;
              modules-left = [
                "custom/os"
                "${wmName}/workspaces"
                "clock"
                "custom/cava"
                "mpris"
              ];
              modules-right = [
                "wlr/taskbar"
                (optionalString osConfig.programs.gamemode.enable "custom/gamemode")
                "custom/bitwarden"
                "custom/airplay"
                "custom/wallRand"
                "custom/wireguard"
                "custom/recording"
                "idle_inhibitor"
                "network"
                "cpu"
                "memory"
                "pulseaudio"
                "custom/swaync"
              ];
            }
            # monitor 2
            {
              output = "${(builtins.elemAt monitors 1).criteria}";
              height = 54;
              modules-left = [
                "clock"
                "mpris"
              ];
              modules-right = [
                "wlr/taskbar"
                "temperature"
                "cpu"
                "memory"
                "pulseaudio"
              ];
            }
          ];
        })

      ];
    };
}
