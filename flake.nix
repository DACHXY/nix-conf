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
      url = "github:nix-community/lanzaboote/v0.4.2";
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

    actual-budget-server = {
      url = "git+file:///home/danny/projects/actual-budget-flake";
      # url = "github:dachxy/actual-budget-flake";
      inputs.nixpkgs.follows = "nixpkgs";
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
      ...
    }@inputs:
    let
      inherit (builtins) mapAttrs;

      hosts = {
        dn-pre7780 = {
          system = "x86_64-linux";
          path = ./system/dev/dn-pre7780;
        };
        dn-server = {
          system = "x86_64-linux";
          path = ./system/dev/dn-server;
        };
        dn-lap = {
          system = "x86_64-linux";
          path = ./system/dev/dn-lap;
        };
        skydrive-lap = {
          system = "x86_64-linux";
          path = ./system/dev/skydrive-lap;
        };
      };
    in
    {
      # ==== NixOS Configuration ==== #
      nixosConfigurations = (
        mapAttrs (
          hostname: conf:
          let
            inherit (conf) path system;
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
              ./options

              # ==== Private Configuration ==== #
              (import path { inherit hostname; })
            ];
          }
        ) hosts
      );

      # ==== MicroVM Packages ==== #
      # packages."${system}" = {
      #   vm-1 = self.nixosConfigurations.vm-1.config.microvm.declaredRunner;
      #   vm-2 = self.nixosConfigurations.vm-2.config.microvm.declaredRunner;
      # };
    };
}
