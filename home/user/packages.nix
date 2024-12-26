{ pkgs, lib, ... }:
let
  vesktop = pkgs.vesktop.overrideAttrs (oldAttrs: {
    desktopItems = lib.optional pkgs.stdenv.hostPlatform.isLinux (
      (lib.head oldAttrs.desktopItems).override {
        name = "discord";
        desktopName = "Discord";
      }
    );
  });
in
{
  home.packages = [
    vesktop # discord
    pkgs.firefox

    # Dev stuff
    pkgs.gcc
    pkgs.go
    pkgs.nodePackages.pnpm
    (pkgs.python3.withPackages
      (python-pkgs: [ python-pkgs.pip python-pkgs.requests ]))
    pkgs.rustup
    pkgs.pkgsCross.mingwW64.stdenv.cc
    pkgs.pkgsCross.mingwW64.windows.pthreads
    pkgs.postman
    pkgs.cz-cli

    # Work stuff
    pkgs.libreoffice-qt

    # Bluetooth
    pkgs.blueberry

    # Gaming
    pkgs.steam-run

    # Downloads
    pkgs.qbittorrent

    # Utils
    pkgs.viewnior
    pkgs.catppuccin-cursors.macchiatoLavender
    pkgs.catppuccin-gtk
    pkgs.cava
    pkgs.papirus-folders
  ];
}
