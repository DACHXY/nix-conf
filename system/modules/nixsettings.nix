{ inputs, ... }:
{
  documentation.nixos.enable = false;
  nix = {
    settings = {
      substituters = [
        "https://yazi.cachix.org"
        # "https://cache.net.dn/dn-main"
      ];
      trusted-public-keys = [
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
        # "dn-main:ZjQmZEOWpe0TjZgHGwkgtPdOUXpN82RL9wy30EW1V7k="
      ];
      warn-dirty = false;
      trusted-users = [
        "@wheel"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };
}
