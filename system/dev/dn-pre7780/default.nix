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

  hardware.nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.stable;

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
    (import ../../modules/virtualization.nix { inherit username; })
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

        # Proton GE
        {
          home.file.".steam/root/compatibilitytools.d/GE-Proton10-10" = {
            source = fetchTarball {
              url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton10-10/GE-Proton10-10.tar.gz";
              sha256 = "sha256:1vkj66x84yqmpqm857hjzmx1s02h2lffcbc60jdfqz9xj34dx5jc";
            };
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
                "move 2061 203, class: ^(GStreamer)$"

                # Bluetooth
                "move 1943 59, class: ^(blueberry.py)$"
                "size 605 763, class: ^(blueberry.py)$"
              ];

              monitor = [
                ''desc:ASUSTek COMPUTER INC ASUS VG32VQ1B 0x00002271, 2560x1440@165, 0x0, 1''
                ''desc:Acer Technologies XV272U V3 1322131231233, 2560x1440@180, -1440x-600, 1, transform, 1''
              ];
            };
          };
        }

        # Git
        (import ../../../home/user/git.nix {
          inherit username;
          email = "danny10132024@gmail.com";
        })
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    rustdesk
    blender
  ];

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
