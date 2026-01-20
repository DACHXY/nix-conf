{ config, lib, ... }:
let
  inherit (lib) mkForce;
  inherit (config.networking) domain;

  # Virtual Domain
  vDomain = "vnet.dn";
  proxyIP = "10.10.0.1";

  cfg = config.services.netbird;
  srv = cfg.server;

  realm = "master";
in
{
  sops.secrets."netbird/wt0-setupKey" = {
    owner = cfg.clients.wt0.user.name;
    mode = "400";
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

  services.nginx.virtualHosts."${srv.domain}" = {
    useACMEHost = domain;
    addSSL = true;
    locations."/api" = {
      extraConfig = ''
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };
  };
}
