{ pkgs, inputs, system, ... }:

let
  terminalContent = ''
    [Nemo Action]
    Name=Open in Ghostty 
    Comment=Open folder in Ghostty 
    Exec=ghostty -e \"cd %F && exec bash\"
    Icon-Name=ghostty
    Selection=any
    Extensions=dir;
    Quote=double
    EscapeSpaces=true
    Dependencies=ghostty;
  '';

  nemo-unwrapped = pkgs.nemo.overrideAttrs (oldAttrs: {
    postInstall = ''
      ${oldAttrs.postInstall}

      # Open in Terminal Patch
      echo "${terminalContent}" > $out/share/nemo/actions/open_in_terminal.nemo_action
    '';
  });
in
{
  environment.systemPackages = (with pkgs; [
    # gtk theme
    gtk3
    adwaita-icon-theme

    # Browser
    firefox

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
    inputs.yazi.packages.x86_64-linux.default # Terminal file manager
    nemo-unwrapped
  ]);
}

