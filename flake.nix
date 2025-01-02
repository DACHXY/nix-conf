{
  description = "danny NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    yazi = {
      url = "github:sxyazi/yazi";
    };

    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    hyprgrass = {
      url = "github:horriblename/hyprgrass";
      inputs.hyprland.follows = "hyprland";
    };

    Hyprspace = {
      url = "github:KZDKM/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs =
    { self, nixpkgs, nix-index-database, ... }@inputs:
    let
      system = "x86_64-linux";
      nix-version = "25.05";
    in
    {
      nixosConfigurations = {
        dn-pre7780 = nixpkgs.lib.nixosSystem {
          modules = [
            nix-index-database.nixosModules.nix-index
            ./system/dev/dn-pre7780
          ];
          specialArgs = {
            inherit inputs system nix-version;
          };
        };

        dn-lap = nixpkgs.lib.nixosSystem {
          modules = [
            nix-index-database.nixosModules.nix-index
            ./system/dev/dn-lap
          ];
          specialArgs = {
            inherit inputs system nix-version;
          };
        };
      };
    };
}
