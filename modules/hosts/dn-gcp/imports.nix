{ config, ... }:
{
  configurations.nixos.dn-gcp.module = {
    imports =
      (with config.flake.modules; [
        nixos.server
        nixos.danny-minimal
        generic.dnywe
      ])
      ++ [
        # Force-disables the desktop stack that the shared base profile pulls in.
        ./_minimal.nix
      ];
  };
}
