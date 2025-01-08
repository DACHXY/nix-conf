{
  pkgs,
  ...
}:
let
  imageLink = "https://images.unsplash.com/photo-1507090960745-b32f65d3113a?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&dl=matteo-catanese-PI8Hk-3ZcCU-unsplash.jpg&w=2400";
  image = pkgs.fetchurl {
    url = imageLink;
    sha256 = "sha256-y0avQR9I8u2m0JEe/lcfLgHUDF1TDN029511yC6PhQE=";
  };
in
pkgs.stdenv.mkDerivation {
  name = "sddm-theme";
  src = pkgs.fetchFromGitHub {
    owner = "MarianArlt";
    repo = "sddm-sugar-dark";
    rev = "ceb2c455663429be03ba62d9f898c571650ef7fe";
    sha256 = "0153z1kylbhc9d12nxy9vpn0spxgrhgy36wy37pk6ysq7akaqlvy";
  };
  installPhase = ''
    mkdir -p $out
    cp -R ./* $out/
    cd $out/
    rm Background.jpg
    cp -r ${image} $out/Background.jpg
  '';
}
