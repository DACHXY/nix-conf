{ ... }:
{
  configurations.nixos.dn-server.module =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      username = config.my.user.name;
    in
    {
      networking.firewall.allowedUDPPorts = [ 8211 ];

      systemd.user.services.pal-world-update = {
        wantedBy = [ "default.target" ];

        script = ''
          ${lib.getExe pkgs.steamcmd} \
            +login anonymous \
            +app_update 2394010 validate \
            +quit
        '';

        serviceConfig = {
          Type = "oneshot";
        };
      };

      # systemd.user.timers.pal-world-update = {
      #   wantedBy = [ "timers.target" ];
      #
      #   timerConfig = {
      #     OnCalendar = "daily";
      #     Persistent = true;
      #   };
      # };

      systemd.user.services.pal-world-server = {
        wantedBy = [ "default.target" ];

        script = ''
          ./PalServer.sh
        '';

        serviceConfig = {
          WorkingDirectory = "/home/${username}/.steam/steam/steamapps/common/PalServer";
          Restart = "on-failure";
          RestartSec = 10;
        };
      };
    };
}
