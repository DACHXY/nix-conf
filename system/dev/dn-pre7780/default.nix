{
  pkgs,
  username,
  config,
  system,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) optionalString;
  geVersion = "10-15";
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
    {
      from = 31000;
      to = 31010;
    }
  ];

  hardware.nvidia.package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.latest;
  hardware.nvidia.open = lib.mkForce true;

  imports = [
    ./boot.nix # Extra Boot Options
    ./sops-conf.nix # Secret
    ./nginx.nix
    ./mail.nix
    # (import ./netbird.nix {
    #   domain = "pre7780.dn";
    #   coturnPassFile = config.sops.secrets."netbird/coturn/password".path;
    #   idpSecret = config.sops.secrets."netbird/oidc/secret".path;
    #   dataStoreEncryptionKey = config.sops.secrets."netbird/dataStoreKey".path;
    # })
    ./hardware-configuration.nix

    ../../modules/presets/basic.nix
    ../../modules/sunshine.nix

    # Nvidia GPU Driver
    (import ../../modules/nvidia.nix {
      nvidia-mode = "offload";
      intel-bus-id = "PCI:0:2:0";
      nvidia-bus-id = "PCI:1:0:0";
    })

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

    (import ../../modules/nextcloud.nix {
      hostname = "nextcloud.pre7780.dn";
      configureACME = true;
      https = true;
      adminpassFile = config.sops.secrets."nextcloud/adminPassword".path;
      trusted = [ "nextcloud.daccc.info" ];
    })

    ../../modules/davinci-resolve.nix
    ../../modules/webcam.nix
    ../../modules/postgresql.nix
  ];

  # Live Sync D
  services.postgresql = {
    ensureUsers = [ { name = "${username}"; } ];
    ensureDatabases = [ "livesyncd" ];
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
    ((blender.override { cudaSupport = true; }).overrideAttrs (prev: {
      postInstall = ''
        sed -i 's|Exec=blender %f|Exec=/run/current-system/sw/bin/nvidia-offload blender %f|' $out/share/applications/blender.desktop
      '';
    }))
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

  home-manager = {
    users."${username}" = {
      imports = [
        ../../../home/presets/basic.nix

        # Bitwarden client
        (import ../../../home/user/bitwarden.nix {
          email = "danny@net.dn";
          baseUrl = "https://bitwarden.net.dn";
        })

        # waybar
        (import ../../../home/user/waybar.nix {
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

        # Hyprland
        (import ../../../home/user/hyprland.nix { inherit monitors; })
        ./hyprland.nix

        # Git
        (import ../../../home/user/git.nix {
          inherit username;
          email = "danny10132024@gmail.com";
        })

        # (import ../../../home/user/wallpaper-engine.nix {
        #   monitorIdPairs = [
        #     {
        #       monitor = "DP-6";
        #       id = "3050040845";
        #     }
        #     {
        #       monitor = "DP-5";
        #       id = "2665674743";
        #     }
        #   ];
        # })
      ];

      home.file = {
        # CS go
        ".steam/steam/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg/autoexec.cfg".text = ''
          fps_max "250"

          # Wheel Jump
          bind "mwheeldown" "+jump"
          bind "mwheelup" "+jump"
          bind "space" "+jump"

          echo "AUTOEXEC LOADED SUCCESSFULLY!"
          host_writeconfig
        '';

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
}
