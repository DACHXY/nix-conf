{ pkgs, ... }:
let
  shellAlias = import ./shellAlias.nix;
in
{
  programs = {
    # nushell = {
    #   enable = true;
    #   configFile.source = ../config/nushell/config.nu;
    #   envFile.source = ../config/nushell/env.nu;
    # };

    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';
      plugins = [
        { name = "grc"; src = pkgs.fishPlugins.grc.src; }
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
