{ pkgs, ... }:
let
  shellAlias = {
    ls = "exa";
    cat = "bat";
    rebuild = "sudo nixos-rebuild switch --flake /etc/nixos";
    fullClean = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";
    setWindows = "sudo bootctl set-oneshot auto-windows";
    goWin = "sudo bootctl set-oneshot auto-windows && reboot";
    goBios = "sudo bootctl set-onshot auto-reboot-to-firmware-setup && reboot";
  };
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
