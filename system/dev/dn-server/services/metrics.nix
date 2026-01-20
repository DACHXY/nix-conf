{
  config,
  lib,
  helper,
  pkgs,
  ...
}:
let
  inherit (helper.grafana) mkDashboard;
  inherit (lib) optionalAttrs optional;
  inherit (config.networking) hostName domain;

  grafanaHostname = "grafana.${domain}";
  prometheusHostname = "metrics.${domain}";

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

  crowdsecSrc = fetchTarball {
    url = "https://github.com/crowdsecurity/grafana-dashboards/archive/c89d8476b32ea76e924c488db7d0afd0306fc609.tar.gz";
    sha256 = "sha256:1s7v03hzss22dkl3hw9qf0qc86qn98wx8x13rvy73wc5mgxv9wnk";
  };

  crowdsecDashboard = mkDashboard {
    name = "crowdsec";
    src = "${crowdsecSrc}/dashboards_v5";
    templateList = datasourceTemplate;
  };

  pdnsRecursorSrc = pkgs.fetchurl {
    name = "pdns-recursor-grafana-dashboard.json";
    url = "https://grafana.com/api/dashboards/20448/revisions/3/download";
    sha256 = "sha256-8lgo+A3dnFLanhGJWCKAo/iPYSMiove17xvMolgq9nI=";
  };

  pdnsRecursorDashboard = mkDashboard {
    name = "pdns-recursor";
    src = "${pdnsRecursorSrc}";
    templateList = datasourceTemplate;
    conf = {
      dontUnpack = true;
    };
  };
in
{
  imports = [
    (import ../../../modules/prometheus.nix {
      fqdn = prometheusHostname;
      selfMonitor = true;
      configureNginx = true;
      scrapes = [
        (optionalAttrs config.services.pdns-recursor.enable {
          job_name = "powerdns_recursor";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.pdns-recursor.api.port}" ];
              labels = {
                machine = "${hostName}";
              };
            }
          ];
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "instance";
              regex = "(.*):[0-9]+";
              replacement = "PDNS Recursor - \${1}";
            }
          ];
        })
      ]
      ++ (optional
        (config.services.crowdsec.enable && config.services.crowdsec.settings.general.prometheus.enabled)
        [
          {
            job_name = "crowdsec";
            static_configs = [
              {
                targets = [
                  "127.0.0.1:${toString config.services.crowdsec.settings.general.prometheus.listen_port}"
                ];
                labels = {
                  machine = "${hostName}";
                };
              }
            ];
            relabel_configs = [
              {
                source_labels = [ "__address__" ];
                target_label = "instance";
                regex = "(.*):[0-9]+";
                replacement = "CrowdSec - \${1}";
              }
            ];
          }
        ]
      );
    })

    (import ../../../modules/grafana.nix {
      domain = grafanaHostname;
      passFile = config.sops.secrets."grafana/password".path;
      smtpHost = "${config.mail-server.hostname}.${config.mail-server.domain}:465";
      smtpDomain = config.mail-server.domain;
      extraSettings = {
        "auth.generic_oauth" =
          let
            OIDCBaseUrl = "https://keycloak.net.dn/realms/master/protocol/openid-connect";
          in
          {
            enabled = true;
            allow_sign_up = true;
            client_id = "grafana";
            client_secret = ''$__file{${config.sops.secrets."grafana/client_secret".path}}'';
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
      extraConf = {
        provision.datasources.settings = {
          prune = true;
          datasources = [
            {
              uid = "prometheus-dn-server";
              name = "Prometheus";
              url = "https://metrics.net.dn";
              type = "prometheus";
            }
          ];
        };
        provision.dashboards.settings.providers = [
          {
            name = "CrowdSec";
            type = "file";
            options.path = "${crowdsecDashboard}";
          }
          {
            name = "PDNSRecursor";
            type = "file";
            options.path = "${pdnsRecursorDashboard}";
          }
        ];
      };
    })
  ];

  services.prometheus.alertmanager-ntfy = {
    settings = {
      http = {
        addr = ":31006";
      };
      ntfy = {
        baseurl = config.services.ntfy-sh.settings.base-url;
        notification = {
          topic = "alertmgr";
          priority = ''
            status == "firing" ? "urgent" : "default"
          '';
          tags = [
            {
              tag = "+1";
              condition = ''status == "resolved"'';
            }
          ];
          templates = {
            title = ''
              {{ if eq .Status "resolved" }}Resolved: {{ end }}{{ index .Annotations "summary" }}
            '';
            description = ''
              {{ index .Annotations "description" }}
            '';
            headers.X-Click = ''
              {{ .GeneratorURL }}
            '';
          };
        };
      };
    };
    enable = true;
  };

  services.nginx.virtualHosts = {
    "${grafanaHostname}" = {
      useACMEHost = domain;
    };
    "${prometheusHostname}" = {
      useACMEHost = domain;
    };
  };
}
