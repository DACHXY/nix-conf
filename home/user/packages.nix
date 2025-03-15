{
  pkgs,
  lib,
  nvidia-offload-enabled,
  ...
}:
let
  discordIcon = lib.readFile ../../pkgs/assets/discord.svg;
  discordSplash = lib.readFile ../../pkgs/assets/peepoLeave.gif.base64;
  vesktopOverride = pkgs.vesktop.overrideAttrs (oldAttrs: {
    desktopItems = lib.optional pkgs.stdenv.hostPlatform.isLinux (
      (lib.head oldAttrs.desktopItems).override {
        name = "discord";
        desktopName = "Discord";
        exec = if nvidia-offload-enabled == true then "offload vesktop %U" else "vesktop %U";
      }
    );

    patches = oldAttrs.patches ++ [
      ../../pkgs/patches/splash.patch
    ];

    # Change Splash
    preConfigure = ''
      echo "${discordSplash}" | base64 -d > static/peepo.gif
    '';

    # Change Icon
    postInstall = ''
      rm -rf $out/share/icons/hicolor/*
      mkdir -p $out/share/icons/hicolor/scalable/apps
      echo '${discordIcon}' > $out/share/icons/hicolor/scalable/apps/vesktop.svg
    '';
  });

  zen-browser = pkgs.callPackage ../../pkgs/zen-browser.nix { };
in
{
  home.packages =
    (with pkgs; [
      # Dev stuff
      gcc
      go
      (python3.withPackages (python-pkgs: [
        python-pkgs.pip
        python-pkgs.requests
        python-pkgs.weasyprint
      ]))
      rustup
      pkgsCross.mingwW64.stdenv.cc
      pkgsCross.mingwW64.windows.pthreads
      postman
      ripdrag

      # Work stuff
      libreoffice-qt
      pandoc
      texliveSmall

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
      inkscape

      # PDF Preview
      poppler

      trash-cli
    ])
    ++ [
      vesktopOverride # discord
      zen-browser
    ];
}
