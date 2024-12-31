{ pkgs, inputs, system, ... }:

{
  environment.systemPackages = (with pkgs; [
    # gtk theme
    gtk3
    adwaita-icon-theme

    # Browser
    firefox

    # File Manager
    nemo

    # Utils
    bat
    btop
    eza
    fzf
    neofetch
    ripgrep
    tree
    tldr # Alternative for man
    wget
    unzip
    p7zip
    killall
    zip
    glxinfo # OpenGL info
    pciutils # PCI info
    xdotool # Keyboard input simulation
    ffmpeg # Video encoding
    mpv # Media player
    brightnessctl

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
    stylua
    lazygit
    lua51Packages.lua
    luajitPackages.magick # neovim
    vimPlugins.neomake

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

    # USB auto mount
    usbutils
    udiskie
    udisks

    # Media
    vlc

    # Thumbnail
    ffmpegthumbnailer
  ]) ++ ([
    inputs.ghostty.packages.${system}.default
  ]);
}


