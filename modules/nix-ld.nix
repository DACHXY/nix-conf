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
        ];
      };
    };
}
