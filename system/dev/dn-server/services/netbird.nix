{ config, lib, ... }:
let
  inherit (lib) mkForce;
  domain = "dnywe.com";

  # Virtual Domain
  vDomain = "vnet.dn";
  proxyIP = "10.10.0.1";

  cfg = config.services.netbird;
  srv = cfg.server;

  # TODO: Change realm to master
  realm = "netbird";
in
{
  sops.secrets."netbird/wt0-setupKey" = {
    owner = cfg.clients.wt0.user.name;
    mode = "400";
  };

  systemConf.security.allowedDomains = [
    "login.dnywe.com"
    "pkgs.netbird.io"
    "${srv.domain}"
  ];

  imports = [
    (import ../../../modules/netbird-server.nix {
      inherit realm vDomain;
      domain = "netbird.${domain}";
      oidcURL = "https://${config.services.keycloak.settings.hostname}";
      enableNginx = false;
      oidcType = "keycloak";
    })
  ];

  services.netbird = {
    ui.enable = mkForce false;

    clients.wt0 = {
      port = 51830;
      openFirewall = true;
      autoStart = true;
      environment = {
        NB_MANAGEMENT_URL = "https://${srv.domain}";
      };
      login = {
        enable = true;
        setupKeyFile = config.sops.secrets."netbird/wt0-setupKey".path;
      };
    };

    server.management = {
      disableSingleAccountMode = false;
      singleAccountModeDomain = vDomain;
      metricsPort = 32009;
      turnDomain = mkForce "coturn.${domain}";
      extraOptions = [ "--user-delete-from-idp" ];
    };

    server.coturn.enable = mkForce false;
  };

  networking.firewall.allowedTCPPorts = [ 32011 ];

  # ==== Proxy By Caddy & CDN ==== #
  services.nginx.appendHttpConfig = ''
    set_real_ip_from ${proxyIP};
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;
  '';

  services.nginx.virtualHosts."netbird.local" = {
    locations = {
      "/" = {
        root = cfg.server.dashboard.finalDrv;
        tryFiles = "$uri $uri.html $uri/ =404";
      };

      "/404.html".extraConfig = ''
        internal;
      '';

      "/api" = {
        extraConfig = ''
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
        proxyPass = "http://127.0.0.1:${builtins.toString srv.management.port}";
      };

      "/management.ManagementService/".extraConfig = ''
        client_body_timeout 1d;

        grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        grpc_pass grpc://127.0.0.1:${builtins.toString srv.management.port};
        grpc_read_timeout 1d;
        grpc_send_timeout 1d;
        grpc_socket_keepalive on;
      '';

      "/signalexchange.SignalExchange/".extraConfig = ''
        client_body_timeout 1d;

        grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        grpc_pass grpc://127.0.0.1:${builtins.toString srv.signal.port};
        grpc_read_timeout 1d;
        grpc_send_timeout 1d;
        grpc_socket_keepalive on;
      '';
    };

    extraConfig = ''
      error_page 404 /404.html;
    '';
  };
}
