{ config, lib, ... }:
let
  inherit (lib) mkForce concatStringsSep;
  inherit (config.networking) domain;

  # Virtual Domain
  vDomain = "vnet.dn";
  proxyIPs = [
    "10.10.0.1"
    "10.20.0.1"
  ];

  cfg = config.services.netbird;
  srv = cfg.server;

  realm = "master";
in
{
  sops.secrets."netbird/wt0-setupKey" = {
    restartUnits = [ "netbird-wt0-login.service" ];
  };

  systemConf.security.allowedDomains = [
    config.services.keycloak.settings.hostname
    "${srv.domain}"
    "pkgs.netbird.io"
  ];

  imports = [
    (import ../../../modules/netbird-server.nix {
      inherit realm vDomain;
      domain = "netbird.${domain}";
      oidcURL = "https://${config.services.keycloak.settings.hostname}";
      enableNginx = true;
      oidcType = "keycloak";
    })
  ];

  services.netbird = {
    useRoutingFeatures = "server";
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

  networking.firewall.allowedTCPPorts = [
    # networking.firewall.interfaces."wg0".allowedTCPPorts = [
    32011
    8011
    8012
  ];

  systemd.services.netbird-wt0 = {
    requires = [
      "netbird-management.service"
      "netbird-signal.service"
    ];
    after = [
      "netbird-management.service"
      "netbird-signal.service"
    ];
    serviceConfig = {
      TimeoutStartSec = "20s";
      TimeoutStopSec = "20s";
      KillSignal = "SIGKILL";
      StartLimitIntervalSec = 0;
      StartLimitBurst = 0;
      Restart = mkForce "no";
    };
  };

  systemd.services.netbird-management = {
    requires = [
      "keycloak.service"
      "dnsdist.service"
      "pdns.service"
      "pdns-recursor.service"
    ];
    after = [
      "keycloak.service"
      "dnsdist.service"
      "pdns.service"
      "pdns-recursor.service"
    ];
  };

  # ==== Proxy By Caddy & CDN ==== #
  services.nginx.appendHttpConfig = ''
    ${concatStringsSep "\n" (map (v: "set_real_ip_from ${v};") proxyIPs)}
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;
  '';

  services.nginx.virtualHosts."${srv.domain}" = {
    useACMEHost = domain;
    addSSL = true;

    extraConfig = ''
      client_header_timeout 1d;
      client_body_timeout 1d;
    '';

    listen = [
      {
        addr = "127.0.0.1";
        port = 30082;
      }
      {
        addr = "0.0.0.0";
        port = 80;
      }
      {
        addr = "0.0.0.0";
        port = 443;
        ssl = true;
      }
    ];

    locations."~ ^/(relay|ws-proxy/)" = {
      proxyPass = "http://127.0.0.1:${toString srv.management.port}";
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 1d;
      '';
    };

    locations."~ ^/(oauth2)/" = {
      proxyPass = "http://127.0.0.1:${toString srv.management.port}";
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
}
