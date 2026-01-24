final: prev: {
  proton-dw-bin =
    let
      steamDisplayName = "Proton DW";
    in
    final.pkgs.stdenv.mkDerivation (finalAttrs: rec {
      pname = "dwproton";
      version = "10.0-14";

      src = final.pkgs.fetchzip {
        url = "https://dawn.wine/dawn-winery/dwproton/releases/download/${pname}-${finalAttrs.version}/${pname}-${finalAttrs.version}-x86_64.tar.xz";
        hash = "sha256-5fDo7YUPhp0OwjdAXHfovSuFCgSPwHW0cSZk9E+FY98=";
      };

      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;

      outputs = [
        "out"
        "steamcompattool"
      ];

      installPhase = ''
        runHook preInstall
        echo "${finalAttrs.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

        mkdir $steamcompattool
        ln -s $src/* $steamcompattool
        rm $steamcompattool/compatibilitytool.vdf
        cp $src/compatibilitytool.vdf $steamcompattool

        runHook postInstall
      '';

      preFixup = ''
        substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
          --replace-fail "${finalAttrs.pname}-${finalAttrs.version}-x86_64" "${steamDisplayName}"
      '';
    });
}
