{ pkgs, ... }:

{
  home.packages = [
    pkgs.vesktop # discord
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
    # pkgs.steam
    pkgs.steam-run
    # (pkgs.lutris.override {
    #   extraPkgs = pkgs: [ pkgs.wineWowPackages.stable pkgs.winetricks ];
    # })

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
