{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services.netbird) hostname vDomain;
  inherit (config.flake.public.config.services) oidc coturn;
  inherit (config.flake.public.config.machines) dn-cc gcp;
in
{
  configurations.nixos.dn-server.module =
    { config, lib, ... }:
    let
      inherit (lib) mkIf mkForce concatStringsSep;
      inherit (config.sops) secrets;
      proxyIPs = [
        dn-cc.ip
        gcp.ip
      ];

      cfg = config.services.netbird;
      srv = cfg.server;
    in
    {
      sops.secrets = {
        "netbird/oidc/secret" = { };
        "netbird/turn/secret" = {
          key = "netbird/oidc/secret";
        };
        "netbird/turn/password" = {
          key = "netbird/coturn/password";
        };
        "netbird/coturn/password" = mkIf config.services.netbird.server.coturn.enable {
          owner = "turnserver";
        };
        "netbird/dataStoreKey" = { };

        "netbird/wt0-setupKey" = {
          restartUnits = [ "netbird-wt0-login.service" ];
        };
      };

      # ==== Server ==== #
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "netbird" ];
        ensureUsers = [
          {
            name = "netbird";
            ensureDBOwnership = true;
          }
        ];
      };

      systemd.services.netbird-management.environment = {
        NETBIRD_STORE_ENGINE_POSTGRES_DSN = "host=/var/run/postgresql user=netbird dbname=netbird";
      };

      services.netbird = {
        ui.enable = false;

        server = {
          enable = true;
          domain = hostname;
          enableNginx = true;

          # ==== Signal ==== #
          signal.enable = true;

          # ==== Management ==== #
          management = {
            enable = true;
            dnsDomain = vDomain;
            disableSingleAccountMode = false;
            singleAccountModeDomain = vDomain;
            metricsPort = 32009;
            turnDomain = coturn.hostname;
            extraOptions = [ "--user-delete-from-idp" ];

            # === turn === #
            oidcConfigEndpoint = oidc.oidcConfigEndpoint;
            settings = {
              StoreConfig.Engine = "postgres";
              DataStoreEncryptionKey = {
                _secret = secrets."netbird/dataStoreKey".path;
              };

              TURNConfig = {
                Secret._secret = secrets."netbird/turn/secret".path;
                Turns = mkForce [
                  {
                    Proto = "udp";
                    URI = "turns:${srv.management.turnDomain}:5349";
                    Username = "netbird";
                    Password._secret = secrets."netbird/turn/password".path;
                  }
                ];
              };
              IdpManagerConfig = {
                ManagerType = "keycloak";
                ClientConfig = {
                  TokenEndpoint = "${oidc.issuer}/protocol/openid-connect/token";
                  ClientID = "netbird-backend";
                  ClientSecret = {
                    _secret = secrets."netbird/oidc/secret".path;
                  };
                };
                ExtraConfig = {
                  AdminEndpoint = "${oidc.endpoint}/admin/realms/${oidc.realm}";
                };
              };
              DeviceAuthorizationFlow.ProviderConfig = {
                Audience = "netbird-client";
                ClientID = "netbird-client";
              };
              PKCEAuthorizationFlow.ProviderConfig = {
                Audience = "netbird-client";
                ClientID = "netbird-client";
              };
            };
          };

          # ==== Dashboard ==== #
          dashboard.settings = {
            AUTH_AUTHORITY = oidc.issuer;
            AUTH_CLIENT_ID = "netbird-client";
            AUTH_AUDIENCE = "netbird-client";
            AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
          };
        };
      };

      # ==== Client ==== #
      services.netbird = {
        useRoutingFeatures = "server";

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
      };

      networking.firewall.allowedTCPPorts = [
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
    };
}
