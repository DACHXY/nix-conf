{ self, config, ... }:
let
  serverCfg = self.nixosConfigurations.dn-server.config;
  inherit (serverCfg.networking) domain;
  dn-server-ip = "10.20.0.2";
  cfg = config.services.traefik;

  nextcloud-forwarded-headers = {
    trustedIPs = [
      "173.245.48.0/20"
      "103.21.244.0/22"
      "103.22.200.0/22"
      "103.31.4.0/22"
      "141.101.64.0/18"
      "108.162.192.0/18"
      "190.93.240.0/20"
      "188.114.96.0/20"
      "197.234.240.0/22"
      "198.41.128.0/17"
      "162.158.0.0/15"
      "104.16.0.0/12"
      "172.64.0.0/13"
      "131.0.72.0/22"
    ];
  };
in
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.traefik = {
    enable = true;

    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":80";
          asDefault = true;
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
          forwardedHeaders = nextcloud-forwarded-headers;
        };

        websecure = {
          address = ":443";
          asDefault = true;
          forwardedHeaders = nextcloud-forwarded-headers;
        };
      };

      log = {
        level = "INFO";
      };

      accessLog = {
        format = "json";
      };

      tls.stores.default.defaultCertificate = {
        certFile = "${config.security.acme.certs."${domain}".directory}/fullchain.pem";
        keyFile = "${config.security.acme.certs."${domain}".directory}/key.pem";
      };

      api.dashboard = true;
    };

    dynamicConfigOptions =
      let
        nextcloudDomain = "nextcloud.${domain}";
      in
      {
        http.routers = {
          nextcloud-router = {
            rule = "Host(`${nextcloudDomain}`)";
            service = "nextcloud-service";
            tls = { };
            middlewares = [ "nextcloud-headers" ];
          };
        };

        http.services = {
          nextcloud-service = {
            loadBalancer.servers = [
              {
                url = "http://${dn-server-ip}";
              }
            ];
          };
        };

        http.middlewares = {
          nextcloud-headers = {
            headers = {
              customRequestHeaders = {
                Host = "${nextcloudDomain}";
                X-Real-IP = "{remoteIP}";
                X-Forwarded-Proto = "https";
                X-Forwarded-For = "{remoteIP}";
              };
            };
          };
        };
      };
  };
}
