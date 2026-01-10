{
  description = "DACHXY's NixOS with hyprland";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    yazi = {
      url = "github:sxyazi/yazi";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-tmodloader = {
      url = "github:andOrlando/nix-tmodloader";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
    };

    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    actual-budget-api = {
      url = "github:DACHXY/actual-budget-api";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixd = {
      url = "github:nix-community/nixd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ===== Nvim Plugins ===== #
    marks-nvim = {
      url = "github:chentoast/marks.nvim";
      flake = false;
    };
    # ======================== #

    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    };

    mail-server = {
      url = "github:dachxy/nix-mail-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mail-ntfy-server = {
      url = "github:dachxy/mail-ntfy-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-search-tv.url = "github:3timeslazy/nix-search-tv";

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-nfsm = {
      url = "github:dachxy/nfsm/feat/hm-module";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks.url = "github:cachix/git-hooks.nix";

    # ==== Shell ==== #
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      ...
    }@inputs:
    let
      inherit (builtins) mapAttrs;
      forEachSystem = nixpkgs.lib.genAttrs (import systems);

      hosts = {
        dn-pre7780 = {
          system = "x86_64-linux";
          confPath = ./system/dev/dn-pre7780;
        };
        dn-server = {
          system = "x86_64-linux";
          confPath = ./system/dev/dn-server;
        };
        dn-lap = {
          system = "x86_64-linux";
          confPath = ./system/dev/dn-lap;
        };
        skydrive-lap = {
          system = "x86_64-linux";
          confPath = ./system/dev/skydrive-lap;
        };
      };
    in
    {
      # ==== NixOS Configuration ==== #
      nixosConfigurations = (
        mapAttrs (
          hostname: conf:
          let
            inherit (conf) confPath system;
            pkgs = import nixpkgs {
              inherit system;
            };
            helper = import ./helper {
              inherit
                pkgs
                ;
              lib = pkgs.lib;
            };
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit
                helper
                inputs
                self
                ;
            };
            modules = [
              # ==== Common Configuration ==== #
              {
                nixpkgs.hostPlatform = system;
                nixpkgs.config.allowUnfree = true;
                nixpkgs.overlays = [
                  inputs.niri.overlays.niri
                  inputs.mail-server.overlay
                  inputs.nix-minecraft.overlay
                  inputs.nix-tmodloader.overlay
                  inputs.rust-overlay.overlays.default
                ]
                ++ (import ./pkgs/overlays);
              }

              # ==== Common Modules ==== #
              inputs.home-manager.nixosModules.default
              inputs.mail-ntfy-server.nixosModules.default
              inputs.nix-index-database.nixosModules.nix-index
              inputs.disko.nixosModules.disko
              inputs.sops-nix.nixosModules.sops
              inputs.nix-minecraft.nixosModules.minecraft-servers
              inputs.nix-tmodloader.nixosModules.tmodloader
              inputs.actual-budget-api.nixosModules.default
              inputs.stylix.nixosModules.stylix
              inputs.attic.nixosModules.atticd
              inputs.mail-server.nixosModules.default
              inputs.niri.nixosModules.niri
              inputs.lanzaboote.nixosModules.lanzaboote
              ./options

              # ==== Private Configuration ==== #
              (import confPath { inherit hostname; })
            ];
          }
        ) hosts
      );

      formatter = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          config = self.checks.${system}.pre-commit-check.config;
          inherit (config) package configFile;
          script = ''
            ${pkgs.lib.getExe package} run --all-files --config ${configFile}
          '';
        in
        pkgs.writeShellScriptBin "pre-commit-run" script
      );

      checks = forEachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          pre-commit-check = inputs.git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt.enable = true;

              check-comment = {
                enable = true;
                name = "check comment";
                entry = "${pkgs.callPackage ./githooks/check-comment.nix { }}";
                files = "\\.nix$";
                pass_filenames = false;
                stages = [ "pre-commit" ];
              };
            };
          };
        }
      );

      devShells = forEachSystem (system: {
        default =
          let
            pkgs = import nixpkgs { inherit system; };
            inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
          in
          pkgs.mkShell {
            inherit shellHook;
            name = "nixos";
            buildInputs = enabledPackages;
          };
      });

      # ==== MicroVM Packages ==== #
      # packages."${system}" = {
      #   vm-1 = self.nixosConfigurations.vm-1.config.microvm.declaredRunner;
      #   vm-2 = self.nixosConfigurations.vm-2.config.microvm.declaredRunner;
      # };
    };
}
