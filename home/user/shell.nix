{ config, pkgs, ... }:
let
  myAliases = {
    cat = "bat";

    fullClean = ''
      nix-collect-garbage --delete-old

      sudo nix-collect-garbage -d

      sudo /run/current-system/bin/switch-to-configuration boot
    '';
    rebuild = "sudo nixos-rebuild switch --flake /etc/nixos/#dn-nix";
    windows = "sudo bootctl set-oneshot auto-windows";
    toWindows = "sudo bootctl set-oneshot auto-windows && reboot";
    toBIOS = "sudo bootctl set-oneshot auto-reboot-to-firmware-setup && reboot";
  };
in {
  programs = {
    nushell = {
      enable = true;
      shellAliases = myAliases;
    };

    zsh = {
       enable = true;
       shellAliases = myAliases;
    };

    carapace.enable = true;
    carapace.enableNushellIntegration = true;

    starship = { 
       enable = true;
    };

    zoxide = {
       enable = true;
       enableNushellIntegration = true;
    };
  };
}
