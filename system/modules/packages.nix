{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Browser
    firefox

    # Utils
    bat
    btop
    eza
    fzf
    ranger # Terminal file manager
    neofetch
    ripgrep
    tree
    tldr # Alternative for man
    wget
    unzip
    p7zip 
    zip
    glxinfo # OpenGL info
    pciutils # PCI info
    xdotool # Keyboard input simulation
    ffmpeg # Video encoding
    mpv # Media player

    # Dev
    git
    gh # Github cli tool
    gnumake
    lm_sensors
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.qt5.qtsvg
    openssl
    openssl.dev
    pkg-config # Include Lib
    nodejs
    yarn-berry
    dotnetCorePackages.sdk_8_0_3xx
    dotnetCorePackages.dotnet_9.sdk
    dotnetCorePackages.dotnet_9.runtime
    dotnetCorePackages.dotnet_9.aspnetcore
    rustup

    # Editor
    neovim
    lua51Packages.lua
    luajitPackages.magick # neovim
    vimPlugins.neomake

    # Misc
    xfce.thunar # File manager

    # Portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr

    # Shell 
    zoxide # Dir jumper
    starship # Shell theme
    carapace # Autocomplete

    # USB auto mount
    usbutils
    udiskie
    udisks

    # Media
    vlc
  ];
}

