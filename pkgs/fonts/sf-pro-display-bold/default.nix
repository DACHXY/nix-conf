{
  stdenvNoCC,
  lib,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "sf-pro-display-bold";
  version = "1.0.0";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/MartinRGB/MAKA_H5_Album_Project/master/design/font/SF_Pro/SF-Pro-Display-Bold.ttf";
    sha256 = "sha256-yjCRiRtzDDAnOxbMg8na+Uu0bw+YUmJhbOqBVdURjxQ=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype/SF-Pro-Display-Bold
    install -m444 $src $out/share/fonts/truetype/SF-Pro-Display-Bold/SF-Pro-Display-Bold.ttf

    runHook postInstall
  '';

  meta = with lib; {
    description = "SF Pro Display Bold font";
    homepage = "https://github.com/MartinRGB/MAKA_H5_Album_Project";
    platforms = platforms.all;
  };
}
