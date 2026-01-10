{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) hostName;
  inherit (config.systemConf) username;
  inherit (lib) optionalString;

  memeSelector = pkgs.callPackage ../../../../home/scripts/memeSelector.nix {
    url = "https://nextcloud.net.dn/public.php/dav/files/pygHoPB5LxDZbeY/";
  };
in
{
  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    memeSelector
  ];

  home-manager.users."${username}" = {
    services.kanshi.settings = [
      {
        profile.name = hostName;
        profile.outputs = [
          {
            criteria = "AU Optronics 0x82ED";
          }
          {
            criteria = "AOC 24B30HM2 27ZQ4HA00101";
            position = "1920,540";
          }
        ];
      }
    ];

    programs.hyprlock.monitors = [
      "desc:AU Optronics"
      "desc:AOC 24B30HM2"
    ];

    wayland.windowManager.hyprland = {
      settings = {
        input.kb_options = lib.mkForce [ ];
        bind = [
          "$mainMod ctrl, M, exec, ${memeSelector}/bin/memeSelector"
        ];
      };
    };
    imports = [
      ../../../../home/presets/basic.nix

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
}
