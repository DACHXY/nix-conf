{ pkgs, ... }:
{
  systemd.timers."certbot-renew" = {
    enable = true;
    description = "certbot renew";
    timerConfig = {
      Persistent = true;
      OnCalendar = "*-*-* 03:00:00";
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
    environment = {
      "REQUESTS_CA_BUNDLE" = ../extra/ca.crt;
    };
    serviceConfig = {
      ExecStart = ''${pkgs.certbot}/bin/certbot renew --no-random-sleep-on-renew --force-renewal'';
      ExecStartPost = "${pkgs.busybox}/bin/chown nginx:nginx -R /etc/letsencrypt";
    };
  };

  systemd.services."nginx-reload-after-certbot" = {
    after = [ "certbot-renew.service" ];
    requires = [ "certbot-renew.service" ];
    wantedBy = [ "certbot-renew.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "nginx";
      # This config file path refers to "services.nginx.enableReload"
      ExecStart = ''${pkgs.nginx}/bin/nginx -s reload -c /etc/nginx/nginx.conf'';
    };
  };

  systemd.services."nginx-config-reload" = {
    serviceConfig = {
      User = "root";
      ExecStartPre = "${pkgs.busybox}/bin/chown -R nginx:nginx /etc/letsencrypt/";
    };
  };
}
