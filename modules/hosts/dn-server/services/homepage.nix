{
  config,
  ...
}:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services.homepage) hostname endpoint alias;
  inherit (config.flake.public.config.services)
    nextcloud
    paperless
    forgejo
    netbird
    oidc
    prometheus
    grafana
    uptime
    vaultwarden
    powerdns
    actual
    ntfy
    ;
in
{
  configurations.nixos.dn-server.module =
    { config, ... }:
    let
      inherit (builtins) concatStringsSep;
      cfg = config.services.homepage-dashboard;
      allowedHosts = concatStringsSep "," (
        [
          hostname
          "localhost:${toString cfg.listenPort}"
        ]
        ++ alias
      );
    in
    {
      sops.secrets."homepage" = { };

      services.homepage-dashboard = {
        enable = true;
        openFirewall = true;
        listenPort = 8044;
        environmentFiles = [ config.sops.secrets."homepage".path ];
        inherit allowedHosts;

        docker = {
          docker = {
            socket = "/var/run/docker.sock";
          };
        };
        widgets = [
          {
            search = {
              provider = "duckduckgo";
              target = "_blank";
            };
          }
          {
            datetime = {
              text_size = "x1";
              format = {
                dateStyle = "short";
                timeStyle = "short";
                hour12 = true;
              };
            };
          }
        ];
        services = [
          {
            "Files & Documents" = [
              {
                "Nextcloud" = {
                  icon = "nextcloud.svg";
                  description = "☁️ Cloud drive";
                  href = nextcloud.endpoint;
                  widgets = [
                    {
                      type = "nextcloud";
                      url = nextcloud.endpoint;
                      key = "{{HOMEPAGE_VAR_NEXTCLOUD_NC_TOKEN}}";
                    }
                  ];
                };
              }
              {
                "Paperless" = {
                  icon = "paperless.svg";
                  description = "PDF editing, tagging, and viewing";
                  href = paperless.endpoint;
                };
              }
            ];
          }
          {
            "Development" = [
              {
                "Forgejo" = {
                  icon = "forgejo.svg";
                  description = "Git repository";
                  href = forgejo.endpoint;
                };
              }
            ];
          }
          {
            "VPN & IDP" = [
              {
                "Netbird" = {
                  icon = "netbird.svg";
                  description = "VPN Service: access internal services";
                  href = netbird.endpoint;
                };
              }
              {
                "Keycloak" = {
                  icon = "keycloak.svg";
                  description = "Identity provider";
                  href = oidc.endpoint;
                };
              }
            ];
          }
          {
            "Monitor" = [
              {
                "Grafana" = {
                  icon = "grafana.svg";
                  description = "Show metrics!";
                  href = grafana.endpoint;
                };
              }
              {
                "Prometheus" = {
                  icon = "prometheus.svg";
                  description = "The web is not that useful 🥀";
                  href = prometheus.endpoint;
                };
              }
              {
                "Uptime Kuma" = {
                  icon = "uptime-kuma.svg";
                  description = "Service health check";
                  href = uptime.endpoint;
                };
              }
            ];
          }
          {
            "Utility" = [
              {
                "Vaultwarden" = {
                  icon = "vaultwarden-light.svg";
                  description = "Password manager";
                  href = vaultwarden.endpoint;
                };
              }
              {
                "PowerDNS" = {
                  icon = "powerdns.svg";
                  description = "DNS record management";
                  href = powerdns.endpoint;
                  widgets =
                    let
                      queryProp = ''job="powerdns_recursor"'';
                    in
                    [
                      {
                        type = "prometheusmetric";
                        url = prometheus.endpoint;
                        refreshInterval = 10000;
                        metrics = [
                          {
                            label = "Up";
                            query = "up{${queryProp}}";
                          }
                          {
                            label = "Query Rate";
                            query = "sum(rate(pdns_recursor_questions{${queryProp}}[1h]))";
                            format = {
                              type = "number";
                              suffix = " req/s";
                            };
                          }
                        ];
                      }
                    ];
                };
              }
              {
                "Actual Budget" = {
                  icon = "actual-budget.svg";
                  description = "Financial budget management";
                  href = actual.endpoint;
                };
              }
              {
                "Ntfy" = {
                  icon = "ntfy.svg";
                  description = "Notification service";
                  href = ntfy.endpoint;
                };
              }
            ];
          }
          {
            "Games" = [
              {
                "Minecraft" = {
                  icon = "minecraft.svg";
                  description = "Minecraft servers";
                  widgets = [
                    {
                      type = "minecraft";
                      fields = [
                        "players"
                        "version"
                        "status"
                      ];
                      url = "udp://mc.${domain}:${toString config.services.velocity.port}";
                    }
                  ];
                };
              }
            ];
          }

        ];
        settings = {
          base = endpoint;
          headerStyle = "boxed";
          title = "DN Home";
          description = "Welcome! maybe?";
          disableUpdateCheck = true;
          providers = {

          };
          quicklaunch = {
            searchDescriptions = true;
            hideInternetSearch = true;
            showSearchSuggestions = true;
            hideVisitURL = true;
            provider = "google";
          };
        };
      };

      services.nginx.virtualHosts."${hostname}" = {
        useACMEHost = domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.listenPort}";
        };
        serverAliases = alias;
      };
    };
}
