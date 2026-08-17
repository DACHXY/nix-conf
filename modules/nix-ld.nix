{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          zlib
          zstd
          stdenv.cc.cc
          curl
          openssl
          attr
          libssh
          bzip2
          libxml2
          acl
          libsodium
          util-linux
          xz
          systemd

          glib

          # Inspired by steam
          # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/st/steam/package.nix#L36-L85
          networkmanager
          vulkan-loader
          libgbm
          libdrm
          libxcrypt
          coreutils
          pciutils
          zenity

          # Verified games requirements
          libxt
          libxmu
          libogg
          libvorbis
          SDL
          SDL2_image
          glew_1_10
          libidn
          tbb

          # Appimages need fuse, e.g. https://musescore.org/fr/download/musescore-x86_64.AppImage
          fuse
          e2fsprogs
        ];
      };
    };
}
