{
  domain,
  oidcURL,
  vDomain ? null,
  enableNginx ? false,
  oidcType ? "keycloak",
  realm ? "netbird",
}:
{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (config.sops) secrets;
  cfg = config.services.netbird;
  srv = cfg.server;
  dnsDomain = if vDomain == null then domain else vDomain;
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
  };

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
    ui.enable = true;

    server = {
      inherit domain enableNginx;
      enable = true;

      # ==== Signal ==== #
      signal.enable = true;

      # ==== Management ==== #
      management = {
        inherit dnsDomain;

        # === turn === #
        oidcConfigEndpoint = "${oidcURL}/realms/${realm}/.well-known/openid-configuration";
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
                URI = "turn:${srv.management.turnDomain}:3478";
                Username = "netbird";
                Password._secret = secrets."netbird/turn/password".path;
              }
            ];
          };
          IdpManagerConfig = {
            ManagerType = oidcType;
            ClientConfig = {
              TokenEndpoint = "${oidcURL}/realms/${realm}/protocol/openid-connect/token";
              ClientID = "netbird-backend";
              ClientSecret = {
                _secret = secrets."netbird/oidc/secret".path;
              };
            };
            ExtraConfig = {
              AdminEndpoint = "${oidcURL}/admin/realms/${realm}";
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
        AUTH_AUTHORITY = "${oidcURL}/realms/${realm}";
        AUTH_CLIENT_ID = "netbird-client";
        AUTH_AUDIENCE = "netbird-client";
        AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
      };

      # ==== Coturn (STUN/TURN) ==== #
      coturn = {
        enable = true;
        passwordFile = secrets."netbird/coturn/password".path;
        useAcmeCertificates = enableNginx;
      };
    };
  };
}
