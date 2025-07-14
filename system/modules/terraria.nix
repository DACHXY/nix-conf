{ pkgs, ... }:
let
  serverPkg = pkgs.tmodloader-server.overrideAttrs (
    final: prev: rec {
      version = "v2025.04.3.0";
      name = "tmodloader-${version}";
      url = "https://github.com/tModLoader/tModLoader/releases/download/${version}/tModLoader.zip";

      src = pkgs.fetchurl {
        inherit url;
        hash = "sha256-cu98vb3T2iGC9W3e3nfls3mYTUQ4sviRHyViL0Qexn0=";
      };
    }
  );
in
{
  services.tmodloader = {
    enable = true;
    servers.pokemon = {
      enable = true;
      openFirewall = true;
      port = 7777;
      autoStart = true;
      package = serverPkg;
      world = "/var/lib/tmodloader/pokemon/Worlds/default.wld";
      autocreate = "large";
      install = [
        3039823461
        2619954303
        2563851005
        3378168037
        3173371762
        2800050107
        2785100219
        3018447913
        2565540604
        2563309347
        2908170107
        2669644269
        3439924021
        2599842771
        2797518634
        2565639705
        3497111954
        2563815443
        2707400823
      ];
    };
  };

}
