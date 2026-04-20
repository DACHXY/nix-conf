{ lib, pkgs, ... }:
let
  inherit (lib) mkMerge;
  vDomain = "vnet.dn";

  # ==== Add hosts here ===== #
  hosts = [
    "phone-dn.${vDomain}"
  ];

  mkSystemdUnit =
    host:
    let
      srvName = "${host}-netbird-keepalive";
    in
    {
      timers."${srvName}" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitAvtiveSec = "10m";
          Unit = "${srvName}.service";
        };
      };

      services."${srvName}" = {
        script = ''
          set -eu
          ${pkgs.iputils}/bin/ping -c 1 -W 2 -q ${host}
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
in
{
  systemd = mkMerge (map mkSystemdUnit hosts);
}
