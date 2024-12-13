{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Browser
    firefox
    opera

    # Utils
    bat
    btop
    eza
    fzf
    neofetch
    ripgrep
    tldr # Alternative for man
    wget
    unzip
    p7zip 
    zip
    glxinfo # OpenGL info
    pciutils # PCI info
    xdotool # Keyboard input simulation

    # Dev
    git
    gnumake
    lm_sensors
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.qt5.qtsvg
    openssl
    openssl.dev
    pkg-config # Include Lib

    # Editor
    neovim

    # Misc
    xfce.thunar # File manager

    # Portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr

    # Shell 
    zoxide # Dir jumper
    nushell # Shell
    starship # Shell theme
    carapace # Autocomplete
  ];
}

