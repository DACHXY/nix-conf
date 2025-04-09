{ pkgs, settings, ... }:
let
  shellAlias = import ./shellAlias.nix { hostname = settings.personal.hostname; };
in
{
  home.packages = with pkgs; [
    # Shell
    fishPlugins.done
    fishPlugins.fzf-fish
    fishPlugins.forgit
    fishPlugins.hydro
    fishPlugins.grc
    grc # Colorize
    zoxide # Dir jumper
    starship # Shell theme
    carapace # Autocomplete
  ];

  programs = {
    fish = {
      enable = true;
      shellInit = ''
        # Yazi
        function y
          set tmp (mktemp -t "yazi-cwd.XXXXXX")
          yazi $argv --cwd-file="$tmp"
          if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
          end
          rm -f -- "$tmp"
        end
      '';
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';
      plugins = [
        {
          name = "grc";
          src = pkgs.fishPlugins.grc.src;
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
