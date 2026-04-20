{
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
    ;

  inherit (helper) capitalize;

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
    enable = (mkEnableOption "Enable system configuration") // {
      default = true;
    };
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
      description = "Domain for system";
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

    windowManager = mkOption {
      type =
        with types;
        nullOr (enum [
          "hyprland"
          "niri"
          "mango"
        ]);
      default = null;
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
}
