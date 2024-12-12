{ config, pkgs, ... }:

{
  nix = {
    settings = {
      warn-dirty = false;
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
  };
}
