{
  pkgs ? import <nixpkgs> { },
  imagemagick,
  file,
  stdenvNoCC,
  ...
}:
let
  makeIconPkg =
    {
      name,
      url,
      sha256,
    }:
    stdenvNoCC.mkDerivation rec {
      inherit name;
      pname = name;

      src = pkgs.fetchurl {
        inherit url sha256;
      };

      dontUnpack = true;

      nativeBuildInputs = [
        imagemagick
        file
      ];

      buildPhase = ''
        mkdir -p $out/share/icons/hicolor/256x256/apps
        mkdir -p $out/share/icons/hicolor/scalable/apps

        fileType=$(file -b --mime-type $src)
        if [ "$fileType" = "image/png" ]; then
          echo "Processing PNG image..."
          magick $src -resize 256x256 $out/share/icons/hicolor/256x256/apps/${name}.png
        elif [ "$fileType" = "image/svg+xml" ]; then
          echo "Processing SVG image..."
          cp $src $out/share/icons/hicolor/scalable/apps/${name}.svg
        else
          echo "Unsupported image type: $fileType"
          exit 1
        fi
      '';

      pathsToLink = [
        "/share/icons"
      ];
    };
in
makeIconPkg
