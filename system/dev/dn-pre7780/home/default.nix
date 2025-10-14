{ config, lib, ... }:
let
  inherit (lib) optionalString;
  inherit (config.systemConf) username;
in
{
  home-manager.users."${username}" = {
    imports = [
      ../../../../home/presets/basic.nix
      ./wm

      # Bitwarden client
      (import ../../../../home/user/bitwarden.nix {
        email = "danny@net.dn";
        baseUrl = "https://bitwarden.net.dn";
      })

      # waybar
      (import ../../../../home/user/waybar.nix {
        settings = [
          # monitor 1
          {
            output = "DP-6";
            height = 48;
            modules-left = [
              "custom/os"
              "hyprland/workspaces"
              "clock"
              "custom/cava"
              "mpris"
            ];
            modules-right = [
              "wlr/taskbar"
              (optionalString config.programs.gamemode.enable "custom/gamemode")
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
            output = "DP-5";
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

      # Git
      (import ../../../../home/user/git.nix {
        inherit username;
        email = "danny10132024@gmail.com";
      })
    ];
  };
}
