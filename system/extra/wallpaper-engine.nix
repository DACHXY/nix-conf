{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.wallpaperEngine;

  scaleTypes = [
    "default"
    "fit"
    "fill"
    "stretch"
  ];
  clampModes = [
    "clamp"
    "border"
    "repeat"
  ];

  generateCommandLine =
    monitors:
    lib.concatStringsSep " " (
      lib.mapAttrsToList (
        monitorName: monitorConfig:
        let
          scaleArg = if monitorConfig.scale != null then "--scaling ${monitorConfig.scale}" else "";
          bgId =
            if monitorConfig.bg != null then
              monitorConfig.bg
            else
              throw "Error: Background (bg) is required for monitor ${monitorName}.";
          bgArg = if cfg.contentDir != null then "${lib.removeSuffix "/" cfg.contentDir}/${bgId}" else bgId;
        in
        (scaleArg + " --screen-root " + monitorName + " " + bgArg)
      ) cfg.monitors
    );

  startup =
    let
      args = lib.concatStringsSep " \\\n  " (
        lib.filter (x: x != "") (
          with lib;
          [
            (optionalString (cfg.extraPrefix != null) cfg.extraPrefix)
            "${pkgs.linux-wallpaperengine}/bin/linux-wallpaperengine"
            (optionalString (cfg.assetsDir != null) "--assets-dir ${cfg.assetsDir}")
            (optionalString (cfg.fps != null) "--fps ${toString cfg.fps}")
            (optionalString (cfg.audio.enable == false) "--silent")
            (optionalString (cfg.audio.autoMute == false) "--noautomute")
            (generateCommandLine cfg.monitors)
            (optionalString (cfg.extraPostfix != null) cfg.extraPostfix)
          ]
        )
      );
    in
    pkgs.writeShellScriptBin "launch-wallpaper-engine" ''
      ${args}
    '';
in

with lib;
{
  options = {
    services.wallpaperEngine = {
      enable = mkOption {
        default = false;
        type = with types; bool;
        description = ''Start Wallpaper Engine for linux'';
      };

      extraPrefix = mkOption {
        default = "";
        type = with types; str;
        description = ''Add extra command to exec'';
      };

      extraPostfix = mkOption {
        default = "";
        type = with types; str;
        description = ''Add extra arguments'';
      };

      fps = mkOption {
        default = null;
        type = with types; nullOr int;
        description = ''Limits the FPS to the given number, useful to keep battery consumption low'';
      };

      audio = {
        enable = mkOption {
          default = false;
          type = with types; bool;
          description = ''Mutes all the sound the wallpaper might produce'';
        };

        autoMute = mkOption {
          default = true;
          type = with types; bool;
          description = ''Automute when an app is playing sound'';
        };

        volume = mkOption {
          default = null;
          type = with types; nullOr int;
          description = ''Sets the volume for all the sounds in the background'';
        };
      };

      assetsDir = mkOption {
        default = null;
        type = with types; nullOr str;
        description = "Steam WallpaperEngine assets directory";
      };

      contentDir = mkOption {
        default = null;
        type = with types; nullOr str;
        description = "Steam WallpaperEngine workshop content directory";
      };

      screenshot = mkOption {
        default = false;
        type = with types; bool;
        description = "Takes a screenshot of the background";
      };

      clamping = mkOption {
        default = "clamp";
        type = with types; enum clampModes;
        description = ''Clamping mode for all wallpapers. Can be clamp, border, repeat. Enables GL_CLAMP_TO_EDGE, GL_CLAMP_TO_BORDER, GL_REPEAT accordingly. Default is clamp.'';
      };

      monitors = mkOption {
        default = { };
        description = ''Monitor to display'';
        example = {
          "HDMI-A-2" = {
            scale = "fill";
            bg = "3029865244";
          };
          "DP-3" = {
            bg = "3029865244";
          };
        };
        type =
          with types;
          attrsOf (
            submodule (
              { ... }:
              {
                options = {
                  scale = mkOption {
                    default = "default";
                    description = ''Scaling mode for wallpaper. Can be stretch, fit, fill, default. Must be used before wallpaper provided.'';
                    type = enum scaleTypes;
                  };

                  bg = mkOption {
                    description = ''Background to use.'';
                    type = str;
                  };
                };
              }
            )
          );
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = (
      (with pkgs; [
        linux-wallpaperengine
      ])
      ++ [ startup ]
    );

    systemd.user.services.wallpaper-engine = {
      enable = true;
      description = "Start Wallpaper Engine after Hyprland";
      after = [
        "wayland-session@Hyprland.target"
      ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${startup}/bin/launch-wallpaper-engine";
        Restart = "always";
        RestartSec = 10;
      };
    };
  };
}
