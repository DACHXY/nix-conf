# Here only set the environment for cuda shell env
# For futher, see flake: https://github.com/DACHXY/python-cuda-flake
{ lib, ... }:
{
  nix = {
    settings = {
      substituters = [
        "https://cuda-maintainers.cachix.org"
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
  };
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "cuda-merged"
    ];
}
