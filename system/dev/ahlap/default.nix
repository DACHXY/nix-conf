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
      nvidia-bus-id = "PCI:59:0:0";
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
              windowrulev2 =
                let
                  top = "60";
                  right = "100%-w-10";
                in
                [
                  # Meidia control
                  "move ${right} ${top}, class: ^(org.pulseaudio.pavucontrol)$"
                  "size 30% 33%, class: ^(org.pulseaudio.pavucontrol)$"

                  # Local Send (File Sharing)
                  "move ${right} 8%, class: ^(localsend_app)$"
                  "size 20% 80%, class: ^(localsend_app)$"

                  # Airplay
                  "move ${right} 10%, class: ^(GStreamer)$"
                  "size 20% 40%, class: ^(GStreamer)$"

                  # Bluetooth
                  "move ${right} ${top}, class: ^(blueberry.py)$"
                  "size 25% 45%, class: ^(blueberry.py)$"
                ];

              input = {
                kb_options = lib.mkForce [ ];
              };
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
