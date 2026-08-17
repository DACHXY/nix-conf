{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.rust-overlay.overlays.default
  ];
}
