{ hostname }:
{
  config,
  inputs,
  pkgs,
  lib,
  modulesPath,
  self,
  helper,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (lib) mkForce;
  serverRules = config.server-rules;

  stateVersion = "25.11";
  username = "danny";
  ip = serverRules.extra.dn-cc.network.ipv4;
  prefix = 25;
  gateway = serverRules.extra.dn-cc.network.gateway;
in
{
  # ==== VMware guest ==== #
  virtualisation.vmware.guest.enable = true;

  # ==== Basic ==== #
  system.stateVersion = stateVersion;
  networking = {
    hostName = hostname;
    domain = "dnywe.com";
  };
  environment.systemPackages = with pkgs; [
    openssl
    neovim
    curl
    gitMinimal
  ];

  # ==== Nix Settings ==== #
  nix = {
    settings = {
      warn-dirty = false;
      trusted-users = [
        "@wheel"
        username
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };

  # ==== System Modules ==== #
  imports = [
    inputs.home-manager.nixosModules.default
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.stylix.nixosModules.stylix
    inputs.nix-index-database.nixosModules.nix-index

    (modulesPath + "/installer/scan/not-detected.nix")
    ./boot.nix
    ./disk.nix
    ./services
    ./security
    ../public/dn/server-rule.nix
    ../../modules/time.nix
    ../../modules/environment.nix
    ../../modules/internationalisation.nix
    ../../modules/misc.nix
    ../../modules/programs.nix
    ../../modules/sops-nix.nix
    ../../modules/security.nix
    ../../modules/systemd-resolv.nix
    (import ./network.nix {
      inherit
        ip
        prefix
        gateway
        username
        ;
    })
  ];

  # ==== Home Manager ==== #
  home-manager = {
    backupFileExtension = "backup-hm";
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit
        username
        hostname
        helper
        inputs
        system
        self
        ;
    };
    sharedModules = [
      inputs.sops-nix.homeManagerModules.default
      inputs.nvf.homeManagerModules.default
    ];

    users.${username} = {
      home = {
        homeDirectory = mkForce "/home/${username}";
        stateVersion = stateVersion;
      };
      programs.home-manager.enable = true;

      imports = [
        ../../../home/user/nvf
        ../../../home/user/environment.nix
        ../../../home/user/direnv.nix

        (import ../../../home/user/git.nix {
          username = "dachxy";
          email = "dachxy@dnywe.com";
        })
      ];

      programs.btop = {
        enable = true;
        settings = {
          theme_background = false;
          update_ms = 1000;
        };
      };
    };
  };

  # Disable man cache
  documentation.man.cache.enable = mkForce false;

  # ==== Users ==== #
  users.users = {
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
    ];

    "${username}" = {
      isNormalUser = true;
      shell = pkgs.bash; # Actually fish
      extraGroups = [
        "wheel"
        "input"
        "docker"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
      ];
    };
  };
}
