{
  description = "danny NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nixpkgs-unstable, nixpkgs, nix-index-database, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgsUnstable = nixpkgs-unstable.legacyPackages.${system};
      nixvim.url = "github:azuwis/lazyvim-nixvim";
    in
    {
      formatter.x86_64-linux =
        nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      nixosConfigurations.dn-pre7780 = nixpkgs.lib.nixosSystem {
        modules = [
          nix-index-database.nixosModules.nix-index
          ./system/dev/dn-pre7780
        ];
        specialArgs = {
          inherit inputs;
          inherit pkgsUnstable;
        };
      };

      nixosConfigurations.dn-lap = nixpkgs.lib.nixosSystem {
        modules = [
          nix-index-database.nixosModules.nix-index
          ./system/dev/dn-lap
        ];
        specialArgs = {
          inherit inputs;
          inherit pkgsUnstable;
        };
      };

      #      homeConfigurations = {
      #        danny = home-manager.lib.homeManagerConfiguration {
      #          inherit pkgs;
      #          modules = [ ./home ];
      #          extraSpecialArgs = {
      #            inherit pkgs-unstable;
      #            inherit inputs;
      #          };
      # };
      #      };
      #      programs.home-manager.enable = true;
    };
}
