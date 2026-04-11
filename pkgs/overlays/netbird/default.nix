final: prev: {
  netbird-ui = final.pkgs.callPackage ./package.nix { componentName = "ui"; };
  netbird = final.pkgs.callPackage ./package.nix { componentName = "client"; };
  netbird-upload = final.pkgs.callPackage ./package.nix { componentName = "upload"; };
  netbird-management = final.pkgs.callPackage ./package.nix { componentName = "management"; };
  netbird-signal = final.pkgs.callPackage ./package.nix { componentName = "signal"; };
  netbird-relay = final.pkgs.callPackage ./package.nix { componentName = "relay"; };
  netbird-dashboard = prev.netbird-dashboard.overrideAttrs (prevAttrs: rec {
    version = "2.36.0";

    src = prev.fetchFromGitHub {
      owner = "netbirdio";
      repo = "dashboard";
      rev = "v${version}";
      hash = "sha256-VsecD83dz6U6jEaGIxv7M9ePzbTPCXeffSoyyBr2Vh4=";
    };

    npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  });
}
