{
  pkgs,
  username,
  config,
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
  memeSelector = pkgs.callPackage ../../../home/scripts/memeSelector.nix {
    url = "https://nextcloud.net.dn/public.php/dav/files/pygHoPB5LxDZbeY/";
  };
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
    ./hardware-configuration.nix
    ../../modules/presets/basic.nix
    ../../modules/sunshine.nix

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

    (import ../../modules/stalwart.nix {
      enableNginx = true;
      domain = "pre7780.dn";
      adminPassFile = config.sops.secrets."stalwart/adminPassword".path;
      dbPassFile = config.sops.secrets."stalwart/db".path;
      acmeConf = {
        directory = "https://ca.net.dn/acme/acme/directory";
        ca_bundle = "${"" + ../../extra/ca.crt}";
        challenge = "dns-01";
        origin = "pre7780.dn";
        contact = "admin@pre7780.dn";
        domains = [
          "pre7780.dn"
          "mx1.pre7780.dn"
        ];
        default = true;
        provider = "rfc2136-tsig";
        host = "10.0.0.1";
        renew-before = "1d";
        port = 5359;
        cache = "${config.services.stalwart-mail.dataDir}/acme";
        key = "stalwart";
        tsig-algorithm = "hmac-sha512";
        secret = "%{file:${config.sops.secrets."stalwart/tsig".path}}%";
      };
    })

    ../../modules/davinci-resolve.nix
    ../../modules/webcam.nix
    ../../modules/postgresql.nix
    ./nginx.nix
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
    memeSelector
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
              bind = [
                "$mainMod ctrl, M, exec, ${memeSelector}/bin/memeSelector"
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
