{
  description = "DACHXY's NixOS with hyprland";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
      "https://yazi.cachix.org"
      "https://ghostty.cachix.org"
      "https://cache.numtide.com"
      "https://nix.unom.io"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "punktfunk-cache-1:yhOJmHxzg6tzXpxSFzlYn6Pc6r0jHprsWqt8MZC654o="
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

    # Pinned nixpkgs whose Mesa is 26.2.0. Mesa >= 26.2.3 dropped
    # EGL_EXT_device_query from the glvnd client extension string, which niri's
    # DRM renderer init requires (niri-wm/niri#2687) -> black screen on NVIDIA.
    # Used only to source `mesa` for hardware.graphics.package (modules/hardware.nix).
    nixpkgs-mesa = {
      url = "github:NixOS/nixpkgs/0ae2bc1419c3f345984c2629e72e7a631820fa4d";
    };

    # Pinned nixpkgs that carries PHP 8.4.27, the release fixing the request
    # lifecycle RCEs CVE-2026-109618 / CVE-2026-109619 ("php2shell", exploited
    # in the wild from 2026-10-21). The main `nixpkgs` input is still on
    # 8.4.26; bumping it would rebuild the whole system, so it is used only to
    # source `php84` via an overlay in
    # modules/hosts/dn-server/services/nextcloud.nix (Nextcloud is the only PHP
    # consumer here). Drop the overlay once `nixpkgs` itself is past 8.4.27.
    nixpkgs-php = {
      url = "github:NixOS/nixpkgs/f27fecd91e88d0a3604d9e0c326670f54cd4683c";
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

    vpnctl = {
      url = "git+https://git.dnywe.com/dachxy/noctalia-vpn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
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
    };

    nix-search-tv.url = "github:3timeslazy/nix-search-tv";

    niri = {
      url = "github:sodiboo/niri-flake/very-refactor";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-pkgs = {
      url = "github:sodiboo/niri-flake";
    };

    git-hooks.url = "github:cachix/git-hooks.nix";

    noctalia = {
      url = "github:DACHXY/noctalia/feat/desktop-widget-tilt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zjstatus = {
      url = "github:dj95/zjstatus";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-nfsm = {
      url = "github:gvolpe/nfsm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    linux-wallpaper-engine = {
      url = "github:jagrat7/linux-wallpaper-engine";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jj-starship.url = "github:dmmulroy/jj-starship";

    woomer.url = "github:coffeeispower/woomer";

    wshowkeys = {
      url = "github:DreamMaoMao/wshowkeys";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents.url = "github:numtide/llm-agents.nix";

    tether = {
      url = "github:zackb/tether";
    };

    ihasmail = {
      url = "github:dachxy/ihasmail/nix-packaging";
    };

    iaudio = {
      url = "git+https://git.dnywe.com/dachxy/iaudio.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ivpn = {
      url = "git+ssh://forgejo@git.dnywe.com/dachxy/ivpn.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nono = {
      url = "github:nolabs-ai/nono";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    vyolune = {
      url = "git+https://git.dnywe.com/dachxy/vyolune?ref=main";
    };

    punktfunk = {
      url = "git+https://git.unom.io/unom/punktfunk?ref=nix-stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AirDrop between iPhones and Linux (AWDL on a non-Broadcom card).
    owly = {
      url = "github:t4t5/owly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs self; } {
      imports = [
        (inputs.import-tree ./modules)
      ];

      _module.args.rootPath = ./.;
    };
}
