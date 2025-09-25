{ osConfig, pkgs, ... }:
let
  shellAlias = import ./shellAlias.nix { hostname = osConfig.networking.hostName; };
  remoteRebuld = pkgs.callPackage ../scripts/remoteRebuild.nix { };
in
{
  home.packages = with pkgs; [
    # Shell
    grc
    remoteRebuld
  ];

  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';
      plugins = [
        {
          name = "grc";
          src = pkgs.fishPlugins.grc.src;
        }
        {
          name = "fzf-fish";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
        {
          name = "forgit";
          src = pkgs.fishPlugins.forgit.src;
        }
        {
          name = "hydro";
          src = pkgs.fishPlugins.hydro.src;
        }
      ];
      shellAliases = shellAlias;
    };

    bash = {
      enable = true;
      # Ghostty intergration in nix-shell
      bashrcExtra = ''
        if [ -n "''${GHOSTTY_RESOURCES_DIR}" ]; then
             builtin source "''${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
         fi
      '';
    };

    carapace = {
      enable = true;
      enableFishIntegration = true;
    };

    starship = {
      enable = true;
      enableFishIntegration = true;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
