{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    neovim
    file

    cachix

    upower
    jq
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

    git
    gh
    gnumake
    lm_sensors
    openssl
    openssl.dev
    pkg-config # Include Lib
    nodejs
    yarn-berry
    rustup
    gcc
    zig

    vim
    stylua
    lazygit
    luajitPackages.lua
    lua51Packages.lua
    luajitPackages.luarocks
    luajitPackages.magick
    imagemagick

    fishPlugins.done
    fishPlugins.fzf-fish
    fishPlugins.forgit
    fishPlugins.hydro
    fishPlugins.grc
    grc # Colorize
    zoxide # Dir jumper
    starship # Shell theme
    carapace # Autocomplete

    usbutils
    udiskie
    udisks

    ffmpegthumbnailer

    libsForQt5.qt5.qtmultimedia
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.qt5.qtsvg
    libsForQt5.qt5.qtwayland
    pkgs.gst_all_1.gst-libav
    pkgs.gst_all_1.gstreamer
    pkgs.gst_all_1.gst-plugins-good
  ];
}
