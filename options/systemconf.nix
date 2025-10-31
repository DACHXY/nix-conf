{
  inputs,
  system,
  config,
  pkgs,
  helper,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    optionals
    ;

  inherit (helper) capitalize;

  stateVersion = "25.05";

  cfg = config.systemConf;
  monitorType =
    with types;
    submodule {
      options = {
        desc = mkOption {
          type = str;
          description = "Hyprland monitor description";
          example = "ASUSTek COMPUTER INC ASUS VG32VQ1B 0x00002271";
        };
        output = mkOption {
          type = str;
          description = "Hyprland monitor output";
          example = "DP-6";
        };
        props = mkOption {
          type = str;
          description = "Hyprland monitor properties";
          default = "prefered, 0x0, 1";
          example = "2560x1440@180, -1440x-600, 1, transform, 1";
        };
      };
    };

  defaultSddmTheme = (
    pkgs.sddm-astronaut.override {
      embeddedTheme = "purple_leaves";
      themeConfig = {
        ScreenWidth = "1920";
        ScreenHeight = "1080";
        Font = "SF Pro Display Bold";
        HeaderText = "Welcome, ${capitalize cfg.username}";
      };
    }
  );
in
{
  options.systemConf = {
    hostname = mkOption {
      type = types.str;
      description = "Hostname for system";
    };

    domain = mkOption {
      type = types.str;
      default = "local";
      description = ''Domain for system'';
    };

    username = mkOption {
      type = types.str;
      description = "Main username";
    };

    sddm = {
      theme = mkOption {
        type = types.str;
        description = "sddm theme name";
        default = "sddm-astronaut-theme";
      };
      package = mkOption {
        type = types.package;
        default = defaultSddmTheme;
        description = "sddm theme package";
      };
    };

    hyprland = {
      enable = (mkEnableOption "Enable hyprland") // {
        default = false;
      };
      monitors = mkOption {
        type = with types; listOf monitorType;
        default = [ ];
        example = [
          {
            desc = "ASUSTek COMPUTER INC ASUS VG32VQ1B 0x00002271";
            output = "DP-6";
            props = "2560x1440@165, 0x0, 1";
          }
        ];
        description = "Monitors used for hyprland and waybar";
      };
    };

    enableHomeManager = (mkEnableOption "Home manager") // {
      default = true;
    };

    nvidia = {
      enable = true;
    };
  };

  config = {
    # ==== System ==== #
    networking = {
      inherit (cfg) domain;
      hostName = cfg.hostname;
    };
    environment.systemPackages = [
      inputs.attic.packages.${system}.attic
    ];
    system.stateVersion = stateVersion;

    # ==== Home Manager ==== #
    home-manager = mkIf cfg.enableHomeManager {
      backupFileExtension = "backup-hm";
      useUserPackages = true;
      useGlobalPkgs = true;
      extraSpecialArgs = {
        inherit helper inputs system;
        inherit (cfg) username;
      };
      users."${cfg.username}" = {
        imports = [
          inputs.hyprland.homeManagerModules.default
          inputs.caelestia-shell.homeManagerModules.default
          inputs.zen-browser.homeManagerModules.${system}.default
          inputs.nvf.homeManagerModules.default
          {
            home = {
              homeDirectory = "/home/${cfg.username}";
              stateVersion = stateVersion;
            };
            programs.home-manager.enable = true;
          }
        ]
        ++ (optionals cfg.hyprland.enable [
          ../home/user/hyprland.nix
        ]);
      };
    };
  };
}
