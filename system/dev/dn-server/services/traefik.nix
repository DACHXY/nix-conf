{ self, config, ... }:
let
  serverCfg = self.nixosConfigurations.dn-server.config;
  inherit (serverCfg.networking) domain;

  netbirdCfg = serverCfg.services.netbird.server;
  server-ip = "127.0.0.1";
  sslCertDir = config.security.acme.certs."${domain}".directory;
in
{
  # ==== Reload Traefik after certificate reload ==== #
  security.acme.certs."${domain}" = {
    postRun = ''
      systemctl reload traefik
    '';
  };

  users.users.traefik.extraGroups = [ "acme" ];

  networking.firewall.allowedTCPPorts = [
    30080
    30443
  ];

  systemd.services.traefik.serviceConfig.LoadCredential = [
    "fullchain.pem:${sslCertDir}/fullchain.pem"
    "key.pem:${sslCertDir}/key.pem"
  ];

  services.traefik = {
    enable = true;

    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":30080";
        };

        websecure = {
          address = ":30443";
          asDefault = true;
          http.tls = true;
        };
      };

      log = {
        level = "INFO";
      };

      accessLog = {
        format = "json";
      };

      tls.stores.default.defaultCertificate = {
        certFile = "/run/credentials/traefik/fullchain.pem";
        keyFile = "/run/credentials/traefik/key.pem";
      };
    };

    dynamicConfigOptions =
      let
        netbirdDomain = "netbird.${domain}";
      in
      {
        http = {
          routers = {
            # gRPC router (needs h2c backend for HTTP/2 cleartext)
            netbird-grpc = {
              rule = "Host(`${netbirdDomain}`) && (PathPrefix(`/signalexchange.SignalExchange/`) || PathPrefix(`/management.ManagementService/`))";
              entrypoints = [ "websecure" ];
              tls = true;
              service = "netbird-server-h2c";
              priority = 100;
            };

            # Backend router (relay, WebSocket, API, OAuth2)
            netbird-backend = {
              rule = "Host(`${netbirdDomain}`) && (PathPrefix(`/relay`) || PathPrefix(`/ws-proxy/`) || PathPrefix(`/api`) || PathPrefix(`/oauth2`))";
              entrypoints = [ "websecure" ];
              tls = true;
              service = "netbird-server";
              priority = 100;
            };

            # Dashboard
            netbird-dashboard = {
              rule = "Host(`${netbirdDomain}`)";
              entrypoints = [ "websecure" ];
              service = "netbird-dashboard";
              tls = { };
              priority = 1;
            };
          };

          # Services
          services = {
            netbird-server.loadbalancer.servers = [
              { url = "http://127.0.0.1:${toString 30082}"; }
            ];
            netbird-server-h2c.loadbalancer.servers = [
              {
                url = "http://127.0.0.1:${toString 30082}";
                scheme = "h2c";
              }
            ];
            netbird-dashboard.loadbalancer.servers = [
              {
                url = "http://127.0.0.1:${toString 30082}";
              }
            ];
          };
        };

      };
  };
}
