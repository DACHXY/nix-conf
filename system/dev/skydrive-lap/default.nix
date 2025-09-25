{
  username,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionalString;
  geVersion = "10-15";
  faceIcon = pkgs.fetchurl {
    url = "https://files.net.dn/skydrive.jpg";
    hash = "sha256-aMjl6VL1Zy+r3ElfFyhFOlJKWn42JOnAFfBXF+GPB/Q=";
    curlOpts = "-k";
  };

  memeSelector = pkgs.callPackage ../../../home/scripts/memeSelector.nix {
    url = "https://nextcloud.net.dn/public.php/dav/files/pygHoPB5LxDZbeY/";
  };

  monitors = [
    "desc:AU Optronics 0x82ED"
    "desc:AOC 24B30HM2 27ZQ4HA00101"
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
    ./disk.nix
    ./sops-conf.nix
    ../../modules/printer.nix
    ../../modules/gaming.nix
    ../../modules/wine.nix
    ../../modules/localsend.nix
    (import ../../modules/airplay.nix { hostname = config.networking.hostName; })
    # (import ../../modules/virtualization.nix { inherit username; })
    ../../modules/wireguard.nix
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
              input = {
                kb_options = lib.mkForce [ ];
              };

              monitor = [
                ''desc:AU Optronics 0x82ED, prefered, 0x0, 1''
                ''desc:AOC 24B30HM2 27ZQ4HA00101, prefered, 1920x540, 1''
              ];

              bind = [
                "$mainMod ctrl, M, exec, ${memeSelector}/bin/memeSelector"
              ];
            };
          };
        }

        (import ../../../home/user/waybar.nix {
          settings = [
            # monitor 1
            {
              output = "eDP-1";
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
            {
              output = "HDMI-A-2";
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

      home.file = {
        # Proton GE
        ".steam/root/compatibilitytools.d/GE-Proton${geVersion}" = {
          source = fetchTarball {
            url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton${geVersion}/GE-Proton${geVersion}.tar.gz";
            sha256 = "sha256:0iv7vak4a42b5m772gqr6wnarswib6dmybfcdjn3snvwxcb6hbsm";
          };
        };
        ".steam/root/compatibilitytools.d/CachyOS-Proton10-0_v3" = {
          source = fetchTarball {
            url = "https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-10.0-20250714-slr/proton-cachyos-10.0-20250714-slr-x86_64_v3.tar.xz";
            sha256 = "sha256:0hp22hkfv3f1p75im3xpif0pmixkq2i3hq3dhllzr2r7l1qx16iz";
          };
        };
      };
    };
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    memeSelector
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
  ];

  users.users."${username}".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBDk8GmC7b9+XSDxnIj5brYmNLPVO47G5enrL3Q+8fuh 好強上的捷徑"
  ];
}
