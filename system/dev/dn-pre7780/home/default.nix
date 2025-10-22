{ config, lib, ... }:
let
  inherit (lib) optionalString;
  inherit (config.systemConf) username;
  inherit (config.systemConf.hyprland) monitors;
in
{
  home-manager.users."${username}" = {
    imports = [
      ../../../../home/presets/basic.nix
      ./expr
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
            output = "${(builtins.elemAt monitors 0).output}";
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
            output = "${(builtins.elemAt monitors 1).output}";
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
