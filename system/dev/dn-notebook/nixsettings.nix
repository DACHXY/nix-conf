{ inputs, config, ... }:
let
  inherit (config.systemConf) username;
in
{
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
        "@admin"
        username
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
  };
}
