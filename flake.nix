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

      devices = {
        dn-pre7780 = {
          settings = {
            personal = {
              hostname = "dn-pre7780";
              domain = "net.dn";
              username = "danny";
              git = {
                username = "DACHXY";
                email = "Danny10132024@gmail.com";
              };
            };

            hyprland = {
              # Leave empty if you only have one monitor
              # This is for assign workspace to a specific monitor
              # e.g. 1, 3, 5 for the first one; 2, 4, 6 for the second one
              monitors = [
                "desc:ASUSTek COMPUTER INC ASUS VG32VQ1B 0x00002271"
                "desc:Acer Technologies XV272U V3 1322131231233"
              ];
              cursor-size = 32;
              xcursor-size = 24;
            };

            # Optional
            nvidia = {
              # Choose from offload, sync, rsync
              mode = "offload";

              # Only needed when using GPU hybrid mode
              intel-bus-id = "PCI:0:2:0";
              nvidia-bus-id = "PCI:1:0:0";
            };
          };
          extra-modules = [
            lanzaboote.nixosModules.lanzaboote
            ./system/dev/dn-pre7780
          ];
          overlays = [

          ];
        };

        dn-lap = {
          settings = {
            personal = {
              hostname = "dn-lap";
              username = "danny";
              git = {
                username = "DACHXY";
                email = "Danny10132024@gmail.com";
              };
            };

            hyprland = {
              # Leave empty if you only have one monitor
              # This is for assign workspace to a specific monitor
              # e.g. 1, 3, 5 for the first one; 2, 4, 6 for the second one
              monitors = [ ];
              cursor-size = 32;
              xcursor-size = 24;
            };
          };
          extra-modules = [
            lanzaboote.nixosModules.lanzaboote
            ./system/dev/dn-lap
          ];
          overlays = [

          ];
        };

        dn-server = {
          settings = {
            personal = {
              hostname = "dn-server";
              username = "danny";
              git = {
                username = "DACHXY";
                email = "Danny10132024@gmail.com";
              };
            };

            hyprland = {
              # Leave empty if you only have one monitor
              # This is for assign workspace to a specific monitor
              # e.g. 1, 3, 5 for the first one; 2, 4, 6 for the second one
              monitors = [ ];
              cursor-size = 32;
              xcursor-size = 24;
            };

            # Optional
            nvidia = {
              # Choose from offload, sync, rsync
              mode = "offload";

              # Only needed when using GPU hybrid mode
              intel-bus-id = "PCI:0:2:0";
              nvidia-bus-id = "PCI:1:0:0";
            };
          };
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
      };
    in
    {
      nixosConfigurations = builtins.mapAttrs (
        dev: conf:
        let
          settings = conf.settings;
          username = settings.personal.username;
          hostname = settings.personal.hostname;
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
                    settings
                    devices
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
              networking.hostName = hostname;
              nixpkgs.hostPlatform = system;
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = ((import ./pkgs/overlays) ++ conf.overlays);
            }
          ]
          ++ common-settings.modules
          ++ conf.extra-modules;
          specialArgs = {
            inherit settings;
          }
          // common-settings.args;
        }
      ) devices;
    };
}
