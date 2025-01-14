{
  pkgs ? import <nixpkgs> { },
  ...
}:
let
  makeIconPkg =
    {
      name,
      url,
      sha256,
    }:
    pkgs.stdenvNoCC.mkDerivation rec {
      inherit name;
      pname = name;

      src = pkgs.fetchurl {
        inherit url sha256;
      };

      dontUnpack = true;

      buildInputs = [ ];
      installPhase = ''
        mkdir -p $out/share/icons
        cp -r $src $out/share/icons
      '';
    };
in
makeIconPkg
