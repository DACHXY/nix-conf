{
  name,
  url,
  sha256,
}:
{
  pkgs,
  imagemagick,
  file,
  stdenvNoCC,
  ...
}:
let
  appName = name;
in
stdenvNoCC.mkDerivation rec {
  pname = "${appName}-icon";
  name = pname;

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
      magick $src -resize 256x256 $out/share/icons/hicolor/256x256/apps/${appName}.png
    elif [ "$fileType" = "image/svg+xml" ]; then
      echo "Processing SVG image..."
      cp $src $out/share/icons/hicolor/scalable/apps/${appName}.svg
    else
      echo "Unsupported image type: $fileType"
      exit 1
    fi
  '';

  pathsToLink = [
    "/share/icons"
  ];
}
