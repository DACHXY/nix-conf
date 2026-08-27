{ lib, ... }:
{
  configurations.nixos.dn-server.module =
    { pkgs, config, ... }:
    {
      environment.systemPackages = with pkgs; [
        steamcmd
        steam-tui
      ];

      programs = {
        gamescope = {
          enable = true;
          capSysNice = true;
          enableWsi = true;
        };
      };

      programs.gamemode = {
        enable = true;
      };

      programs.steam = {
        enable = true;
        protontricks.enable = true;
        gamescopeSession.enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        extraCompatPackages = with pkgs; [
          dwproton-bin
          proton-ge-bin
        ];
        extraPackages = with pkgs; [
          mangohud
          gamescope
        ];
      };

      hardware = {
        steam-hardware.enable = true;
        xpadneo.enable = true;
      };

      services = {
        xserver.enable = false; # Assuming no other Xserver needed
        # getty.autologinUser = config.my.user.name;
        greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${lib.getExe pkgs.gamescope} --backend drm --prefer-vk-device 10de:2438 -O HDMI-A-1 -W 2560 -H 1440 -f -e --xwayland-count 2 --hdr-enabled --hdr-itm-enabled -- steam -pipewire-dmabuf -gamepadui -steamdeck -steamos3";
              user = config.my.user.name;
            };
          };
        };
      };

      networking.hosts = {
        "2.19.181.11" = [ "client-download.steampowered.com" ];
        "2.19.181.10" = [ "client-download.steampowered.com" ];
      };
    };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-unwrapped"
    ];
}
