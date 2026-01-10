{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    getExe'
    ;
  cfg = config.services.sunsetr;
in
{
  options.services.sunsetr = {
    enable = mkEnableOption "Enable sunsetr.";
    package = mkPackageOption pkgs "sunsetr" { };
  };

  config = mkIf cfg.enable {
    systemd.user.services.sunsetr = {
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Unit = {
        Description = "Blue light filter";
      };
      Service = {
        ExecStart = "${getExe' cfg.package "sunsetr"}";
        Restart = "always";
        RestartSec = 2;
      };
    };
  };
}
