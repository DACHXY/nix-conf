{
  pkgs,
  lib,
  config,
  ...
}:
{
  systemd.timers."certbot-renew" = {
    enable = true;
    description = "certbot renew";
    timerConfig = {
      Persistent = true;
      OnCalendar = "*-*-* 16:30:00";
      Unit = "certbot-renew.service";
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.timers."certbot-nginx-reload" = lib.mkIf config.services.nginx.enable {
    enable = true;
    description = "certbot renew";
    timerConfig = {
      Persistent = true;
      OnCalendar = "*-*-* 16:32:00";
      Unit = "nginx-config-reload.service";
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.services."certbot-renew" = {
    enable = true;
    after = (if config.services.nginx.enable then [ "nginx.service" ] else [ ]) ++ [
      "network.target"
    ];
    environment = {
      "REQUESTS_CA_BUNDLE" = ../extra/ca.crt;
    };
    serviceConfig = {
      ExecStart = ''${pkgs.certbot}/bin/certbot renew --no-random-sleep-on-renew --force-renewal'';
      ExecStartPost = lib.mkIf config.services.nginx.enable "${pkgs.busybox}/bin/chown nginx:nginx -R /etc/letsencrypt";
    };
  };

  systemd.services."nginx-config-reload" = lib.mkIf config.services.nginx.enable {
    after = [ "certbot-renew.service" ];
    wantedBy = [ "certbot-renew.service" ];
    serviceConfig = {
      User = "root";
      ExecStartPre = "${pkgs.busybox}/bin/chown -R nginx:nginx /etc/letsencrypt/";
    };
  };
}
