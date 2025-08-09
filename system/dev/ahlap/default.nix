{
  username,
  config,
  lib,
  pkgs,
  ...
}:
let
  faceIcon = pkgs.fetchurl {
    url = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRwExkFtlGxRWflUTcPCfneHSC8E0WuIWNbvkQ4-5_R8x4BXCYx";
    hash = "sha256-OXP3iv7JOz/uhw4P90m54yY5j79gDBBVdoySFZmYAZY=";
  };

  monitors = [
  ];
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/presets/basic.nix

    # Nvidia GPU Driver
    (import ../../modules/nvidia.nix {
      nvidia-mode = "offload";
      intel-bus-id = "PCI:0:2:0";
      nvidia-bus-id = "PCI:1:0:0";
    })

    ./boot.nix # Extra Boot Options
    ../../modules/gaming.nix
    ../../modules/wine.nix
    ../../modules/localsend.nix
    (import ../../modules/airplay.nix { hostname = config.networking.hostName; })
    # (import ../../modules/virtualization.nix { inherit username; })
    # ../../modules/wireguard.nix
  ];

  home-manager = {
    users."${username}" = {
      imports = [
        ../../../home/presets/basic.nix

        {
          home.file.".face" = {
            source = lib.mkForce faceIcon;
          };
        }

        # Hyprland
        (import ../../../home/user/hyprland.nix { inherit monitors; })
        {
          wayland.windowManager.hyprland = {
            settings = {
              windowrulev2 = [
                # Meidia control
                "move 1680 59, class: ^(org.pulseaudio.pavucontrol)$"
                "size 868 561, class: ^(org.pulseaudio.pavucontrol)$"

                # Local Send (File Sharing)
                "size 523 1372, class: ^(localsend_app)$"
                "move 2024 56, class: ^(localsend_app)$"

                # Airplay
                "size 487 1055, class: ^(GStreamer)$"

                # Bluetooth
                "move 1943 59, class: ^(blueberry.py)$"
                "size 605 763, class: ^(blueberry.py)$"
              ];
            };
          };

        }

        # Git
        (import ../../../home/user/git.nix {
          inherit username;
          email = "skyblocksians@gmail.com";
        })
      ];
    };
  };

  users.users."${username}".openssh.authorizedKeys.keys = [
  ];
}
