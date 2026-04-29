{
  pkgs,
  lib,
  osConfig,
  config,
  ...
}:
let
  inherit (lib) mkBefore;
  inherit (osConfig.systemConf) hostname;
  inherit (config.home) homeDirectory;
in
{
  home.packages = with pkgs; [
    # Shell
    grc
    eza
    bat
  ];

  programs = {
    direnv = {
      enable = true;
      enableFishIntegration = true;
      nix-direnv.enable = true;
    };

    fish = {
      enable = true;
      interactiveShellInit = mkBefore ''
        set fish_greeting # Disable greeting

        if test -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
            source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        end

        if test -f /nix/var/nix/profiles/default/etc/profile.d/nix.fish
            source /nix/var/nix/profiles/default/etc/profile.d/nix.fish
        end
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
      shellAliases = {
        ls = "exa --icons";
        lp = "exa"; # Pure output
        cat = "bat";
        g = "git";
        t = "tmux";
        podt = "podman-tui";
        rebuild = "sudo darwin-rebuild --flake ${homeDirectory}/nix#${hostname} switch";
      };
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
