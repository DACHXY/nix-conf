{ ... }:
{
  documentation.nixos.enable = false;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.rcomSupport = true;
}
