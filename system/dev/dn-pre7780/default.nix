{
  pkgs,
  username,
  config,
  lib,
  ...
}:
let
  monitors = [
    "desc:ASUSTek COMPUTER INC ASUS VG32VQ1B 0x00002271"
    "desc:Acer Technologies XV272U V3 1322131231233"
  ];
in
{
  networking.firewall.allowedTCPPortRanges = [
    {
      from = 8000;
      to = 8100;
    }
  ];

  hardware.nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.latest;
  hardware.nvidia.open = lib.mkForce true;

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
    ./sops-conf.nix # Secret
    ../../modules/gaming.nix
    # ../../modules/secure-boot.nix
    ../../modules/virtualization.nix
    ../../modules/wine.nix
    ../../modules/wireguard.nix
    ../../modules/localsend.nix
    (import ../../modules/airplay.nix { hostname = "pre7780"; })
    (import ../../modules/rustdesk-server.nix {
      relayHosts = [
        "10.0.0.0/24"
        "192.168.0.0/24"
      ];
    })

    ../../modules/davinci-resolve.nix
    ../../modules/webcam.nix
    ./nginx.nix
  ];

  home-manager = {
    users."${username}" = {
      imports = [
        ../../../home/presets/basic.nix

        # Bitwarden client
        (import ../../../home/user/bitwarden.nix {
          email = "danny@net.dn";
          baseUrl = "https://bitwarden.net.dn";
        })

        # Proton Extra Versions
        {
          home.file.".steam/root/compatibilitytools.d/GE-Proton10-10" = {
            source = fetchTarball {
              url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton10-10/GE-Proton10-10.tar.gz";
              sha256 = "sha256:1vkj66x84yqmpqm857hjzmx1s02h2lffcbc60jdfqz9xj34dx5jc";
            };
          };
          home.file.".steam/root/compatibilitytools.d/CachyOS-Proton10-0_v3" = {
            source = fetchTarball {
              url = "https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-10.0-20250714-slr/proton-cachyos-10.0-20250714-slr-x86_64_v3.tar.xz";
              sha256 = "sha256:0hp22hkfv3f1p75im3xpif0pmixkq2i3hq3dhllzr2r7l1qx16iz";
            };
          };
        }

        # waybar
        (import ../../../home/user/waybar.nix {
          settings =
            let
              id = 5;
            in
            [
              # monitor 1
              {
                output = "DP-${toString id}";
                modules-left = [
                  "custom/os"
                  "hyprland/workspaces"
                  "clock"
                  "custom/cava"
                  "mpris"
                ];
                modules-right = (
                  [
                    "wlr/taskbar"
                  ]
                  ++ (
                    if config.programs.gamemode.enable then
                      [
                        "gamemode"
                      ]
                    else
                      [ ]
                  )
                  ++ [
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
                  ]
                );
              }
              # monitor 2
              {
                output = "DP-${toString (id + 1)}";
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

        # Hyprland
        (import ../../../home/user/hyprland.nix { inherit monitors; })
        {
          wayland.windowManager.hyprland = {
            settings = {
              monitor = [
                ''desc:ASUSTek COMPUTER INC ASUS VG32VQ1B 0x00002271, 2560x1440@165, 0x0, 1''
                ''desc:Acer Technologies XV272U V3 1322131231233, 2560x1440@180, -1440x-600, 1, transform, 1''
              ];

              misc = {
                vrr = 0;
              };
            };
          };
        }

        # Git
        (import ../../../home/user/git.nix {
          inherit username;
          email = "danny10132024@gmail.com";
        })

        # Cs go
        {
          home.file.".steam/steam/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg/autoexec.cfg".text =
            ''
              fps_max "250"

              # Wheel Jump
              bind "mwheeldown" "+jump"
              bind "mwheelup" "+jump"
              bind "space" "+jump"

              echo "AUTOEXEC LOADED SUCCESSFULLY!"
              host_writeconfig
            '';
        }
      ];
    };
  };

  # Power Management
  services.tlp = {
    enable = true;
    settings = {
      INTEL_GPU_MIN_FREQ_ON_AC = 500;
    };
  };

  environment.systemPackages = with pkgs; [
    rustdesk
    blender
  ];

  services.openssh = {
    settings = {
      UseDns = false;
    };
  };

  users.users = {
    ${username} = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMj/LeB3i/vca3YwGNpAjf922FgiY2svro48fUSQAjOv Shortcuts on :D"
      ];
    };
  };

}
