{
  inputs,
  config,
  pkgs,
  helper,
  lib,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    ;

  inherit (helper) capitalize;

  stateVersion = "25.11";

  cfg = config.systemConf;
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

    face = mkOption {
      type = with types; nullOr path;
      description = "User avatar";
      default = null;
      apply =
        img:
        (
          if img != null then
            pkgs.runCommand "user-face"
              {
                buildInputs = with pkgs; [ imagemagick ];
              }
              ''
                size=$(identify -format "%[fx:min(w,h)]" ${img})
                magick ${img} -gravity center -crop "''\${size}x''\${size}+0+0" -resize 512x512 $out
              ''
          else
            null
        );
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
    };

    niri = {
      enable = (mkEnableOption "Enable niri") // {
        default = false;
      };
    };

    enableHomeManager = (mkEnableOption "Home manager") // {
      default = true;
    };

    nvidia = {
      enable = (mkEnableOption "Enable nvidia configuration") // {
        default = false;
      };
    };
  };

  config = {
    # ==== System ==== #
    networking = {
      inherit (cfg) domain;
      hostName = cfg.hostname;
    };

    system.stateVersion = stateVersion;

    programs.hyprland.enable = if (cfg.hyprland.enable && (!cfg.niri.enable)) then true else false;

    # ==== Home Manager ==== #
    home-manager = mkIf cfg.enableHomeManager {
      backupFileExtension = "backup-hm";
      useUserPackages = true;
      useGlobalPkgs = true;
      extraSpecialArgs = {
        inherit helper inputs system;
        inherit (cfg) username hostname;
      };
      sharedModules = [
        inputs.hyprland.homeManagerModules.default
        inputs.caelestia-shell.homeManagerModules.default
        inputs.sops-nix.homeManagerModules.default
        inputs.zen-browser.homeModules.twilight
        inputs.nvf.homeManagerModules.default
        inputs.noctalia.homeModules.default
        inputs.niri-nfsm.homeModules.default
      ];
      users.${cfg.username} = {
        home = {
          homeDirectory = "/home/${cfg.username}";
          stateVersion = stateVersion;
        };
        programs.home-manager.enable = true;

        home.file.".face" = mkIf (cfg.face != null) {
          source = cfg.face;
        };
      };
    };
  };
}
