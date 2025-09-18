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
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
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

    zen-browser = {
      url = "github:dachxy/zen-browser-flake";
    };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    actual-budget-api = {
      url = "github:DACHXY/actual-budget-api";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
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
      url = "github:NotAShelf/nvf";
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
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-index-database,
      lanzaboote,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      nix-version = "25.05";

      pkgs = import nixpkgs {
        inherit system;
      };

      inherit (pkgs) lib;

      helper = import ./helper { inherit pkgs lib; };

      # Declare COMMON modules here
      common-settings = {
        modules = [
          home-manager.nixosModules.default
          nix-index-database.nixosModules.nix-index
          inputs.sops-nix.nixosModules.sops
          inputs.chaotic.nixosModules.default
          inputs.actual-budget-api.nixosModules.default
          inputs.stylix.nixosModules.stylix
        ];
        args = {
          inherit
            helper
            inputs
            system
            nix-version
            self
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

            # VM
            inputs.microvm.nixosModules.host
            {
              networking.useNetworkd = true;
              systemd.network.enable = true;
              systemd.network.networks."10-lan" = {
                matchConfig.Name = [
                  "enp0s31f6"
                  "vm-*"
                ];
                networkConfig = {
                  Bridge = "br0";
                };
              };

              systemd.network.netdevs."br0" = {
                netdevConfig = {
                  Name = "br0";
                  Kind = "bridge";
                };
              };

              systemd.network.networks."10-lan-bridge" = {
                matchConfig.Name = "br0";
                networkConfig = {
                  Address = [ "192.168.0.5/24" ];
                  Gateway = "192.168.0.1";
                  DNS = [ "192.168.0.1" ];
                };

                linkConfig.RequiredForOnline = "routable";
              };

              microvm.vms = {
                vm-1 = {
                  flake = self;
                  updateFlake = "git+file:///etc/nixos";
                  autostart = false;
                };
                vm-2 = {
                  flake = self;
                  updateFlake = "git+file:///etc/nixos";
                  autostart = false;
                };
              };
            }
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
            ./pkgs/options/dovecot.nix
          ];
          overlays = [
            inputs.nix-minecraft.overlay
            inputs.nix-tmodloader.overlay
            (import ./pkgs/overlays/dovecot.nix)
          ];
        };

        # Skydrive
        skydrive-lap = {
          hostname = "skydrive-lap";
          username = "skydrive";
          domain = "sky.dn";
          extra-modules = [
            inputs.nix-minecraft.nixosModules.minecraft-servers
            inputs.nix-tmodloader.nixosModules.tmodloader
            inputs.disko.nixosModules.disko
            ./system/dev/skydrive-lap
          ];
          overlays = [
            inputs.nix-minecraft.overlay
            inputs.nix-tmodloader.overlay
          ];
        };
      };
    in
    {
      nixosConfigurations =
        (builtins.mapAttrs (
          dev: conf:
          let
            domain = if conf.domain != null then conf.domain else "local";
            inherit (conf) username hostname;
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
                      helper
                      inputs
                      system
                      nix-version
                      devices
                      username
                      ;
                  };
                  users."${username}" = lib.mkIf (!((conf ? isVM) && (conf.isVM))) {
                    imports = [
                      inputs.hyprland.homeManagerModules.default
                      inputs.caelestia-shell.homeManagerModules.default
                      inputs.zen-browser.homeManagerModules.${system}.default
                      inputs.nvf.homeManagerModules.default
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
                nixpkgs.overlays = (import ./pkgs/overlays) ++ conf.overlays;
              }
            ]
            ++ common-settings.modules
            ++ conf.extra-modules;
            specialArgs = {
              inherit username;
            }
            // common-settings.args;
          }
        ) devices)
        //
          # VM For k8s
          (
            let
              vmList =
                let
                  kubeMasterIP = "192.168.0.6";
                  kubeMasterHostname = "api.kube";
                  kubeMasterAPIServerPort = 6443;
                  kubeApi = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
                in
                {
                  # master
                  vm-1 = {
                    ip = "192.168.0.6";
                    mac = "02:00:00:00:00:01";
                    extraConfig = {
                      networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";
                      environment.systemPackages = with pkgs; [
                        kompose
                        kubectl
                        kubernetes
                      ];

                      services.kubernetes = {
                        roles = [
                          "master"
                          "node"
                        ];

                        masterAddress = kubeMasterHostname;
                        apiserverAddress = kubeApi;
                        easyCerts = true;
                        apiserver = {
                          securePort = kubeMasterAPIServerPort;
                          advertiseAddress = kubeMasterIP;
                        };

                        addons.dns.enable = true;
                      };

                      systemd.services.link-kube-config = {
                        wantedBy = [ "multi-user.target" ];
                        serviceConfig = {
                          Type = "oneshot";
                          ExecStart = "${pkgs.writeShellScript "link-kube-config.sh" ''
                            target="/etc/kubernetes/cluster-admin.kubeconfig"
                            if [ -e "$target" ]; then
                              [ ! -d "/root/.kube" ] && mkdir -p "/root/.kube"
                              ln -sf $target /root/.kube/config
                            fi
                          ''}";
                        };
                      };
                    };
                  };
                  # Node
                  vm-2 = {
                    ip = "192.168.0.7";
                    mac = "02:00:00:00:00:02";
                    extraConfig = {
                      networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";

                      environment.systemPackages = with pkgs; [
                        kompose
                        kubectl
                        kubernetes
                      ];

                      services.kubernetes = {
                        roles = [ "node" ];
                        masterAddress = kubeMasterHostname;
                        easyCerts = true;

                        kubelet.kubeconfig.server = kubeApi;
                        apiserverAddress = kubeApi;
                        addons.dns.enable = true;
                      };
                    };
                  };
                };

              mkMicrovm = name: value: {
                hypervisor = "qemu";
                vcpu = 4;
                mem = 8192;
                interfaces = [
                  {
                    type = "tap";
                    id = "${name}";
                    mac = value.mac;
                  }
                ];
                shares = [
                  {
                    tag = "ro-store";
                    source = "/nix/store";
                    mountPoint = "/nix/.ro-store";
                  }
                ];
              };
            in
            lib.mapAttrs' (
              name: value:
              lib.nameValuePair name (
                nixpkgs.lib.nixosSystem {
                  inherit system;
                  modules = [
                    inputs.microvm.nixosModules.microvm
                    value.extraConfig
                    {
                      microvm = mkMicrovm name value;
                      system.stateVersion = lib.trivial.release;
                      networking.hostName = name;
                      networking.domain = "kube";
                      networking.firewall.enable = false;
                      users.users.root.password = "";
                      services.getty.autologinUser = "root";

                      programs.fish.enable = true;
                      programs.bash = {
                        shellInit = ''
                          if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
                          then
                            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
                            exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
                          fi
                        '';
                      };

                      systemd.network.enable = true;
                      systemd.network.networks."20-lan" = {
                        matchConfig.Type = "ether";
                        networkConfig = {
                          Address = [ "${value.ip}/24" ];
                          Gateway = "192.168.0.1";
                          DNS = [ "192.168.0.1" ];
                          DHCP = "no";
                        };
                      };

                      systemd.services.br-netfilter = {
                        wantedBy = [ "multi-user.target" ];
                        serviceConfig = {
                          ExecStart = "/run/current-system/sw/bin/modprobe br_netfilter";
                        };
                      };

                      environment.systemPackages = with pkgs; [
                        dig.dnsutils
                        openssl

                        fishPlugins.done
                        fishPlugins.fzf-fish
                        fishPlugins.forgit
                        fishPlugins.hydro
                        fzf
                        fishPlugins.grc
                        grc
                        git
                      ];
                    }
                  ];
                }
              )
            ) vmList
          )
        // {
          vps = nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = common-settings.args;
            modules = [
              inputs.disko.nixosModules.disko
              ./system/dev/generic
            ];
          };
        };

      packages."${system}" = {
        vm-1 = self.nixosConfigurations.vm-1.config.microvm.declaredRunner;
        vm-2 = self.nixosConfigurations.vm-2.config.microvm.declaredRunner;
      };
    };
}
