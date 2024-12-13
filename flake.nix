{
  description = "danny NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nixpkgs-unstable, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pkgsUnstable = import nixpkgs-unstable { inherit system; };
    in {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      nixosConfigurations.dn-nix = nixpkgs.lib.nixosSystem {
        modules =
          [ 
	    ./system/configuration.nix
	    inputs.home-manager.nixosModules.default
	  ];
        specialArgs = { inherit inputs; inherit pkgsUnstable; };
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
