{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.systemConf) username;
in
{
  nix = {
    settings = {
      substituters = [ "https://nix-gaming.cachix.org" ];
      trusted-public-keys = [
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
    };
  };

  programs.gamescope.enable = lib.mkDefault true;

  users.users.${username}.extraGroups = [ "gamemode" ];

  programs = {
    steam = {
      enable = true;
      protontricks.enable = true;
      gamescopeSession.enable = true;
      extest.enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;

      extraPackages = with pkgs; [
        mangohud
        gamescope
      ];
    };

    gamemode = {
      enable = true;
      settings.general.inhibit_screensaver = 0;
    };
  };

  hardware = {
    steam-hardware.enable = true;

    # Xbox controller
    xpadneo.enable = true;

    # Xbox USB dongle
    xone.enable = true;
  };

  boot.extraModulePackages = with config.boot.kernelPackages; [
    xpadneo
  ];
}
