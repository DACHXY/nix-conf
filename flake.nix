{
  description = "DACHXY's NixOS with hyprland";

  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://yazi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
    ];
    extra-experimental-features = [
      "pipe-operators"
      "flakes"
    ];
    allow-import-from-derivation = true;
  };

  inputs.self.submodules = true;

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree = {
      url = "github:vic/import-tree";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    yazi = {
      url = "github:sxyazi/yazi";
    };

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

    sops-nix = {
      url = "github:Mic92/sops-nix";
    };

    zen-nebula = {
      url = "github:JustAdumbPrsn/zen-nebula";
      flake = false;
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ===== Nvim Plugins ===== #
    marks-nvim = {
      url = "github:chentoast/marks.nvim";
      flake = false;
    };
    # ======================== #

    mail-server = {
      url = "github:dachxy/nix-mail-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-search-tv.url = "github:3timeslazy/nix-search-tv";

    niri = {
      url = "github:sodiboo/niri-flake/very-refactor";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-pkgs = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks.url = "github:cachix/git-hooks.nix";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zjstatus = {
      url = "github:dj95/zjstatus";
    };
  };

  outputs =
    {
      self,
      ...
    }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs self; } {
      imports = [
        (inputs.import-tree ./modules)
      ];

      _module.args.rootPath = ./.;
    };
}
