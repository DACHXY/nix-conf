{
  pkgs,
  inputs,
  system,
  ...
}:
{
  environment.systemPackages =
    (with pkgs; [
      neovim

      # Binary cache platform
      cachix

      # gtk theme
      gtk3
      adwaita-icon-theme

      # File Manager
      nemo

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
      gcc

      # Editor
      vim
      stylua
      lazygit
      luajitPackages.lua
      lua51Packages.lua
      luajitPackages.luarocks
      luajitPackages.magick
      imagemagick

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

      # SDDM
      libsForQt5.qt5.qtmultimedia
      libsForQt5.qt5.qtquickcontrols2
      libsForQt5.qt5.qtgraphicaleffects
      libsForQt5.qt5.qtsvg
      pkgs.gst_all_1.gst-libav
      pkgs.gst_all_1.gstreamer
      pkgs.gst_all_1.gst-plugins-good
    ])
    ++ [
      inputs.ghostty.packages.${system}.default
      inputs.yazi.packages.${system}.default
    ];
}
