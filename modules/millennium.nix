{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.millennium.overlays.default
  ];

  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      programs.steam.package = pkgs.millennium-steam;
    };
}
