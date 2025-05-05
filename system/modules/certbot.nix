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
    environment = {
      "REQUESTS_CA_BUNDLE" = ../extra/ca.crt;
    };
    serviceConfig = {
      ExecStart = ''${pkgs.certbot}/bin/certbot renew'';
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
}
