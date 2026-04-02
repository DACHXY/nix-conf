final: prev: {
  netbird-ui = final.pkgs.callPackage ./package.nix { componentName = "ui"; };
  netbird = final.pkgs.callPackage ./package.nix { componentName = "client"; };
  netbird-upload = final.pkgs.callPackage ./package.nix { componentName = "upload"; };
  netbird-management = final.pkgs.callPackage ./package.nix { componentName = "management"; };
  netbird-signal = final.pkgs.callPackage ./package.nix { componentName = "signal"; };
  netbird-relay = final.pkgs.callPackage ./package.nix { componentName = "relay"; };
  netbird-dashboard = prev.netbird-dashboard.overrideAttrs (prevAttrs: rec {
    version = "2.35.0";

    src = prev.fetchFromGitHub {
      owner = "netbirdio";
      repo = "dashboard";
      rev = "v${version}";
      hash = "sha256-eqDH0mtxb756M6G0pC+FmbZtgj0vk9uKXnzCHlPEquE=";
    };

    npmDepsHash = "sha256-AYbTtUgo/e9BD5Kg877qUHkj+4l2OJ88rxnquA2789k=";
  });
}
