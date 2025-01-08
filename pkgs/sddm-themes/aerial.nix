{
  pkgs,
  lib,
  stdenvNoCC,
  themeConfig ? null,
}:
stdenvNoCC.mkDerivation {
  name = "aerial-sddm-theme";

  dontWrapQtApps = true;

  src = pkgs.fetchFromGitHub {
    owner = "3ximus";
    repo = "aerial-sddm-theme";
    rev = "484b52e";
    sha256 = "sha256-YeJTdlnGV58MNB8VpjDrFuC3VNsh5SgTdZH63aLD6Xw=";
  };

  installPhase =
    let
      iniFormat = pkgs.formats.ini { };
      configFile = iniFormat.generate "" { General = themeConfig; };
      basePath = "$out/share/sddm/themes/sddm-aerial-theme";
    in
    ''
      mkdir -p ${basePath}
      cp -r $src/* ${basePath}
    ''
    + lib.optionalString (themeConfig != null) ''
      ln -sf ${configFile} ${basePath}/theme.conf.user
    '';

}
