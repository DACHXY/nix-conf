{
  src,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  inherit src;

  dontUnpack = true;
  dontBuild = true;

  pname = "dfkai-sb";
  version = "1.0.0";

  installPhase = ''
    runHook preInstall

    install -Dm 644 $src -t $out/share/fonts/truetype

    runHook postInstall
  '';
}
