{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [
      inputs.nix-index-database.nixosModules.nix-index
    ];
  };

  flake.modules.darwin.base = {
    imports = [
      inputs.nix-index-database.darwinModules.nix-index
    ];
  };

  flake.modules.homeManager.base = {
    programs.nix-index = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
