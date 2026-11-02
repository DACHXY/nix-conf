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

      dwproton = pkgs.dwproton-bin.overrideAttrs (
        _: _: {
          version = "dwproton-11.0-14";
          src = pkgs.fetchzip {
            url = "https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-11.0-14/dwproton-11.0-14-x86_64.tar.xz";
            hash = "sha256-dXtOdfqIU0wWQ0OXDRbHuFTifGJ7ti+Ij4g+a/RV71Q=";
          };
        }
      );

    in
    {
      users.users.${username}.extraGroups = [ "gamemode" ];

      programs.gamemode = {
        enable = true;
        settings.general.inhibit_screensaver = 0;
      };

      programs.steam = {
        enable = true;
        gamescopeSession.enable = true;
        extest.enable = true;
        extraCompatPackages = with pkgs; [
          proton-ge-bin
          dwproton-bin
          dwproton
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
