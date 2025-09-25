{
  username,
  config,
  ...
}:
let
  monitors = [
    ''desc:LG Display 0x0665''
  ];
in
{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./sops-conf.nix
    ../../modules/printer.nix
    ../../modules/presets/basic.nix
    ../../modules/gaming.nix
    ../../modules/virtualization.nix
    ../../modules/wine.nix
    ../../modules/wireguard.nix
    (import ../../modules/airplay.nix { })
    # ../../modules/battery-life.nix
  ];

  home-manager = {
    users."${username}" = {
      imports = [
        ../../../home/presets/basic.nix
        (import ../../../home/user/bitwarden.nix {
          email = "danny@dn-server.net.dn";
          baseUrl = "https://bitwarden.net.dn";
        })

        # Hyprland
        (import ../../../home/user/hyprland.nix { inherit monitors; })
        {
          wayland.windowManager.hyprland = {
            settings = {
              monitor = [
                ''desc:LG Display 0x0665, preferred, 0x0, 1.25''
              ];
            };
          };

        }

        # waybar
        (import ../../../home/user/waybar.nix {
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
        (import ../../../home/user/git.nix {
          inherit username;
          email = "danny10132024@gmail.com";
        })
      ];
    };
  };

  users.users."${username}".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMj/LeB3i/vca3YwGNpAjf922FgiY2svro48fUSQAjOv Shortcuts on :D"
  ];
}
