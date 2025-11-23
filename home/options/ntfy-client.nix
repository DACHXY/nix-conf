{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkPackageOption
    mkOption
    types
    mkIf
    getExe'
    ;

  cfg = config.services.ntfy-client;
in
{
  options.services.ntfy-client = {
    enable = mkEnableOption "enable ntfy client subscription";
    package = mkPackageOption pkgs "ntfy-sh" { };
    extraArgs = mkOption {
      type = with types; listOf str;
      default = [ ];
    };
    settings = mkOption {
      type = with types; attrs;
      description = "The settings for `client.yml`";
      default = { };
      example = literalExpression ''
        {
          default-host = "https://ntfy.sh";
          subscribe = [
            {
              topic = "common";
              command = ''\''notify-send "$m"''\'';
              token = "$TOKEN";
            }
          ];
        }
      '';
    };

    environmentFile = mkOption {
      type = with types; path;
      default = null;
      description = "environmentFile contains secrets";
      example = ''
        /var/run/secrets

        content:

        NTFY_USER="username:password"
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      configFile = (pkgs.formats.yaml { }).generate "ntfy-client.yml" cfg.settings;
    in
    {
      systemd.user.services.ntfy-client = {
        Unit.X-Restart-Triggers = [ config.xdg.configFile."ntfy/client.yml".source ];
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${getExe' cfg.package "ntfy"} subscribe --from-config ${toString cfg.extraArgs}";
          EnvironmentFile = [
            cfg.environmentFile
          ];
        };
      };

      xdg.configFile."ntfy/client.yml".source = configFile;
    }
  );
}
