{ config, pkgs, ... }:
let
  myAliases = {
    cat = "bat";
    ls = "eza --icons=always";

    fullClean = ''
      nix-collect-garbage --delete-old

      sudo nix-collect-garbage -d

      sudo /run/current-system/bin/switch-to-configuration boot
    '';
    rebuild = "sudo nixos-rebuild switch --flake /etc/nixos/#dn-nix";
  };
in {
  programs = {
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      initExtra = ''
        source ~/.p10k.zsh && 
        eval "$(zoxide init --cmd cd zsh)" && 
      '';
      shellAliases = myAliases;
      oh-my-zsh = {
        enable = true;
        custom = "$HOME/.oh-my-custom";
        theme = "powerlevel10k/powerlevel10k";
        plugins = [ "git" "history" "wd" ];
      };
    };
  };
}
