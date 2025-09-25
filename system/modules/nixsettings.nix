{ inputs, ... }:
{
  documentation.nixos.enable = false;
  nix = {
    settings = {
      substituters = [
        "https://cache.net.dn/dn-main"
      ];
      trusted-public-keys = [
        "dn-main:ZjQmZEOWpe0TjZgHGwkgtPdOUXpN82RL9wy30EW1V7k="
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
