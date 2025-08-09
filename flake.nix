{
  description = "DACHXY NixOS with hyprland";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    firefox = {
      url = "github:nix-community/flake-firefox-nightly";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty?rev=7f9bb3c0e54f585e11259bc0c9064813d061929c";
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

    hyprtasking = {
      url = "github:raybbian/hyprtasking";
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
    };

    nix-tmodloader = {
      url = "github:andOrlando/nix-tmodloader";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
    };

    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    swww = {
      url = "github:LGFae/swww";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-index-database,
      lanzaboote,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      nix-version = "25.05";

      # Declare COMMON modules here
      common-settings = {
        modules = [
          home-manager.nixosModules.default
          nix-index-database.nixosModules.nix-index
          inputs.sops-nix.nixosModules.sops
        ];
        args = {
          inherit
            inputs
            system
            nix-version
            ;
        };
      };

      # Declaring All Devices
      devices = {
        # Home Computer
        dn-pre7780 = {
          hostname = "dn-pre7780";
          domain = "net.dn";
          username = "danny";
          extra-modules = [
            lanzaboote.nixosModules.lanzaboote
            ./system/dev/dn-pre7780
          ];
          overlays = [ ];
        };

        # Laptop
        dn-lap = {
          hostname = "dn-lap";
          username = "danny";
          domain = "net.dn";
          extra-modules = [
            lanzaboote.nixosModules.lanzaboote
            ./system/dev/dn-lap
          ];
          overlays = [

          ];
        };

        # Server
        dn-server = {
          hostname = "dn-server";
          username = "danny";
          domain = "net.dn";
          extra-modules = [
            inputs.nix-minecraft.nixosModules.minecraft-servers
            inputs.nix-tmodloader.nixosModules.tmodloader
            ./system/dev/dn-server
          ];
          overlays = [
            inputs.nix-minecraft.overlay
            inputs.nix-tmodloader.overlay
          ];
        };

        # Yu lap
        ahlap = {
          hostname = "ahlap";
          username = "ahhaha9119";
          extra-modules = [
            inputs.nix-minecraft.nixosModules.minecraft-servers
            inputs.nix-tmodloader.nixosModules.tmodloader
            ./system/dev/ahlap
          ];
          overlays = [
            inputs.nix-minecraft.overlay
            inputs.nix-tmodloader.overlay
          ];
        };
      };
    in
    {
      nixosConfigurations = builtins.mapAttrs (
        dev: conf:
        let
          inherit (conf) username hostname domain;
        in
        nixpkgs.lib.nixosSystem {
          modules = [
            {
              system.stateVersion = nix-version;
              home-manager = {
                backupFileExtension = "backup-hm";
                useUserPackages = true;
                useGlobalPkgs = true;
                extraSpecialArgs = {
                  inherit
                    inputs
                    system
                    nix-version
                    devices
                    username
                    ;
                };
                users."${username}" = {
                  imports = [
                    inputs.hyprland.homeManagerModules.default
                    {
                      home = {
                        homeDirectory = "/home/${username}";
                        stateVersion = nix-version;
                      };
                      # Let Home Manager install and manage itself.
                      programs.home-manager.enable = true;
                    }
                  ];
                };
              };
              networking = {
                inherit domain;
                hostName = hostname;
              };
              nixpkgs.hostPlatform = system;
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = ((import ./pkgs/overlays) ++ conf.overlays);
            }
          ]
          ++ common-settings.modules
          ++ conf.extra-modules;
          specialArgs = {
            inherit username;
          }
          // common-settings.args;
        }
      ) devices;
    };
}
