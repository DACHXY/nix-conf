{
  nix.settings = {
    extra-substituters = [ "https://nix-gaming.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];
  };

  flake.modules.nixos.gaming =
    { config, pkgs, ... }:
    let
      username = config.my.user.name;
    in
    {
      users.users.${username}.extraGroups = [ "gamemode" ];

      programs.gamemode = {
        enable = true;
        settings.general.inhibit_screensaver = 0;
      };

      programs.steam = {
        enable = true;
        protontricks.enable = true;
        gamescopeSession.enable = true;
        extest.enable = true;
        extraCompatPackages = with pkgs; [
          proton-ge-bin
          dwproton-bin
        ];
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;

        extraPackages = with pkgs; [
          mangohud
          gamescope
        ];
      };

      hardware = {
        steam-hardware.enable = true;
        # Xbox controller
        xpadneo.enable = true;
      };
    };

  flake.modules.homeManager.minecraft =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        prismlauncher
      ];
    };
}
