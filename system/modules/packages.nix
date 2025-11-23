{
  pkgs,
  inputs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  environment.systemPackages = with pkgs; [
    file

    man-pages
    man-pages-posix
    stdmanpages

    # Binary cache platform
    cachix

    # Utils
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
    mesa-demos # OpenGL info
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
    pkg-config
    nodejs
    yarn-berry
    rustup
    gcc
    zig

    # Media
    vlc

    # Search nixpkgs util
    inputs.nix-search-tv.packages.${system}.default
  ];
}
