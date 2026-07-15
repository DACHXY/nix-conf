{ config, self, ... }:
let
  inherit (self.lib.grafana) mkDashboard;
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services) oidc mailserver prometheus;
  inherit (config.flake.public.config.services.grafana) hostname endpoint;

  smtpHost = mailserver.hostname;
  email = "grafana@${domain}";
in
{
  configurations.nixos.dn-server.module =
    { pkgs, ... }@nixosArgs:
    let
      datasourceTemplate = [
        {
          current = {
            text = "Prometheus";
            value = "prometheus-dn-server";
          };
          label = "DS_PROMETHEUS";
          name = "DS_PROMETHEUS";
          options = [ ];
          query = "prometheus";
          refresh = 1;
          regex = "";
          type = "datasource";
        }
      ];

      pdnsRecursorSrc = pkgs.fetchurl {
        name = "pdns-recursor-grafana-dashboard.json";
        url = "https://grafana.com/api/dashboards/20448/revisions/3/download";
        sha256 = "sha256-8lgo+A3dnFLanhGJWCKAo/iPYSMiove17xvMolgq9nI=";
      };

      pdnsRecursorDashboard = mkDashboard {
        inherit pkgs;
        name = "pdns-recursor";
        src = "${pdnsRecursorSrc}";
        templateList = datasourceTemplate;
        conf = {
          dontUnpack = true;
        };
      };
    in
    {
      sops.secrets = {
        "grafana/password" = {
          mode = "0660";
          owner = "grafana";
          group = "grafana";
        };
        "grafana/client_secret" = {
          mode = "0660";
          owner = "grafana";
          group = "grafana";
        };
      };

      services.postgresql = {
        ensureDatabases = [ "grafana" ];
        ensureUsers = [
          {
            name = "grafana";
            ensureDBOwnership = true;
          }
        ];
      };

      services.grafana = {
        enable = true;
        settings = {
          server = {
            http_addr = "127.0.0.1";
            http_port = 31003;
            root_url = endpoint;
            domain = hostname;
          };
          smtp = {
            enabled = true;
            user = "grafana";
            password = "$__file{${nixosArgs.config.sops.secrets."grafana/password".path}}";
            host = smtpHost;
            from_address = email;
            cert_file = nixosArgs.config.security.pki.caBundle;
          };
          security = {
            admin_email = email;
            admin_password = "$__file{${nixosArgs.config.sops.secrets."grafana/password".path}}";
            secret_key = "$__file{${nixosArgs.config.sops.secrets."grafana/password".path}}";
          };
          database = {
            type = "postgres";
            user = "grafana";
            name = "grafana";
            host = "/var/run/postgresql";
          };
          "auth.generic_oauth" =
            let
              OIDCBaseUrl = "${oidc.issuer}/protocol/openid-connect";
            in
            {
              enabled = true;
              allow_sign_up = true;
              client_id = "grafana";
              client_secret = "$__file{${nixosArgs.config.sops.secrets."grafana/client_secret".path}}";
              scopes = "openid email profile offline_access roles";
              email_attribute_path = "email";
              login_attribute_path = "username";
              name_attribute_path = "username";
              auth_url = "${OIDCBaseUrl}/auth";
              token_url = "${OIDCBaseUrl}/token";
              api_url = "${OIDCBaseUrl}/userinfo";
              role_attribute_path = "contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'";
            };
        };

        provision.datasources.settings = {
          prune = true;
          datasources = [
            {
              uid = "prometheus-dn-server";
              name = "Prometheus";
              url = prometheus.endpoint;
              type = "prometheus";
            }
          ];
        };
        provision.dashboards.settings.providers = [
          {
            name = "PDNSRecursor";
            type = "file";
            options.path = "${pdnsRecursorDashboard}";
          }
        ];
      };

      services.nginx.virtualHosts."${hostname}" = {
        forceSSL = true;
        useACMEHost = domain;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString nixosArgs.config.services.grafana.settings.server.http_port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
      };
    };
}
