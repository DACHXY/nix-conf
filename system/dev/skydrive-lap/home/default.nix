{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.systemConf) username;
  inherit (lib) mkForce optionalString;

  memeSelector = pkgs.callPackage ../../../../home/scripts/memeSelector.nix {
    url = "https://nextcloud.net.dn/public.php/dav/files/pygHoPB5LxDZbeY/";
  };

  faceIcon = pkgs.fetchurl {
    url = "https://files.net.dn/skydrive.jpg";
    hash = "sha256-aMjl6VL1Zy+r3ElfFyhFOlJKWn42JOnAFfBXF+GPB/Q=";
    curlOpts = "-k";
  };
in
{

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    memeSelector
  ];

  home-manager = {
    users."${username}" = {
      imports = [
        ../../../../home/presets/basic.nix

        {
          home.file.".face" = {
            source = mkForce faceIcon;
          };
        }

        {
          wayland.windowManager.hyprland = {
            settings = {
              input = {
                kb_options = lib.mkForce [ ];
              };

              bind = [
                "$mainMod ctrl, M, exec, ${memeSelector}/bin/memeSelector"
              ];
            };
          };
        }

        (import ../../../../home/user/waybar.nix {
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
    };
  };
}
