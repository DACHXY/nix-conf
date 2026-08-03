{ inputs, ... }:
{
  configurations.nixos.generic.module = {
    imports = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ];
  };
}
