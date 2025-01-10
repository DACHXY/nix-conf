{
  pkgs,
  lib,
  ...
}: let
  vesktop = pkgs.vesktop.overrideAttrs (oldAttrs: {
    desktopItems = lib.optional pkgs.stdenv.hostPlatform.isLinux (
      (lib.head oldAttrs.desktopItems).override {
        name = "discord";
        desktopName = "Discord";
      }
    );
  });
in {
  home.packages =
    (with pkgs; [
      # Dev stuff
      gcc
      go
      nodePackages.pnpm
      (python3.withPackages
        (python-pkgs: [python-pkgs.pip python-pkgs.requests]))
      rustup
      pkgsCross.mingwW64.stdenv.cc
      pkgsCross.mingwW64.windows.pthreads
      postman
      cz-cli

      # Work stuff
      libreoffice-qt

      # Bluetooth
      blueberry

      # Gaming
      steam-run

      # Downloads
      qbittorrent

      # Utils
      viewnior
      catppuccin-cursors.macchiatoLavender
      catppuccin-gtk
      cava
      papirus-folders
    ])
    ++ [
      vesktop # discord
    ];
}
