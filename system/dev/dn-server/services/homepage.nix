{ config, ... }:
let
  inherit (config.networking) domain;
  cfg = config.services.homepage-dashboard;
in
{
  sops.secrets = {
    "homepage" = {
    };
  };

  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    listenPort = 8044;
    environmentFile = config.sops.secrets."homepage".path;
    allowedHosts = "www.${domain},${domain},localhost:${toString cfg.listenPort}";
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
              href = "https://${config.services.nextcloud.hostName}";
              widgets = [
                {
                  type = "nextcloud";
                  url = "https://${config.services.nextcloud.hostName}";
                  key = "{{HOMEPAGE_VAR_NEXTCLOUD_NC_TOKEN}}";
                }
              ];
            };
          }
          {
            "Paperless" = {
              icon = "paperless.svg";
              description = "PDF editing, tagging, and viewing";
              href = config.services.paperless.settings.PAPERLESS_URL;
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
              href = "https://${config.services.netbird.server.domain}";
            };
          }
          {
            "Keycloak" = {
              icon = "keycloak.svg";
              description = "Identity provider";
              href = "https://${config.services.keycloak.settings.hostname}";
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
              href = config.services.grafana.settings.server.root_url;
            };
          }
          {
            "Prometheus" = {
              icon = "prometheus.svg";
              description = "The web is not that useful 🥀";
              href = config.services.prometheus.webExternalUrl;
            };
          }
          {
            "Uptime Kuma" = {
              icon = "uptime-kuma.svg";
              description = "Service health check";
              href = "https://uptime.${domain}";
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
              href = config.services.vaultwarden.config.DOMAIN;
            };
          }
          {
            "PowerDNS" = {
              icon = "powerdns.svg";
              description = "DNS record management";
              href = "https://powerdns.${domain}";
            };
          }
          {
            "Actual Budget" = {
              icon = "actual-budget.svg";
              description = "Financial budget management";
              href = "https://actual.${domain}";
            };
          }
          {
            "Ntfy" = {
              icon = "ntfy.svg";
              description = "Notification service";
              href = config.services.ntfy-sh.settings.base-url;
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
      base = "https://www.${domain}";
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

  services.nginx.virtualHosts."${domain}" = {
    useACMEHost = domain;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString cfg.listenPort}";
    };
    serverAliases = [
      "www.${domain}"
    ];
  };
}
