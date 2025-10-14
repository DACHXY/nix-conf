{ config, ... }:
let
  inherit (config.systemConf) username;
in
{
  home-manager = {
    users."${username}" = {
      imports = [
        ../../../../home/presets/basic.nix
        (import ../../../../home/user/bitwarden.nix {
          email = "danny@dn-server.net.dn";
          baseUrl = "https://bitwarden.net.dn";
        })

        # waybar
        (import ../../../../home/user/waybar.nix {
          settings = [
            {
              output = "eDP-1";
              height = 46;
              modules-left = [
                "custom/os"
                "hyprland/workspaces"
                "clock"
                "mpris"
              ];
              modules-right = [
                "wlr/taskbar"
                "temperature"
                "custom/wallRand"
                "custom/wireguard"
                "custom/recording"
                "idle_inhibitor"
                "network"
                "pulseaudio"
                "battery"
                "custom/swaync"
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
  };
}
