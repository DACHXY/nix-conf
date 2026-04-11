{ config, inputs, ... }:
let
  inherit (config.systemConf) username;
in
{
  documentation.nixos.enable = true;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep 5 --keep-since 3d";
    flake = "/etc/nixos";
  };

  nix = {
    settings = {
      substituters = [
        "https://yazi.cachix.org"
      ];
      trusted-public-keys = [
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      ];
      warn-dirty = false;
      trusted-users = [
        "@wheel"
        username
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
