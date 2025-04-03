{ config }:
prev: final: {
  imports = [
    ./ferium.nix
    (import ./vesktop.nix { inherit config; })
  ];
}
