{ pkgs, ... }:
{
  systemd.timers."certbot-renew" = {
    enable = true;
    description = "certbot renew";
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      OnUnitActiveSec = "1d";
      Unit = "certbot-renew.service";
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.services."certbot-renew" = {
    enable = true;
    after = [
      "nginx.service"
      "network.target"
    ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      "REQUESTS_CA_BUNDLE" = ../extra/ca.crt;
    };
    serviceConfig = {
      ExecStart = "${pkgs.certbot}/bin/certbot renew";
    };
  };
}
