{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services.nextcloud) hostname endpoint;
  inherit (config.flake.public.config.services) coturn mailserver talk;
  inherit (config.flake.public.config.machines) dn-cc gcp;
in
{
  configurations.nixos.dn-server.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf mkDefault mkAfter;
      inherit (config.sops) secrets;
      spreedCfg = config.services.nextcloud-spreed-signaling;
    in
    {
      sops.secrets = {
        "nextcloud/smtpPassword" = {
          owner = "nextcloud";
          group = "nextcloud";
        };
        "nextcloud/adminPassword" = { };
        "nextcloud/whiteboard" = {
          owner = "nextcloud";
        };
        "nextcloud/spreed/turnPassword" = {
          key = "netbird/coturn/password";
          owner = spreedCfg.user;
        };
        "nextcloud/spreed/turnSecret" = {
          key = "netbird/oidc/secret";
          owner = spreedCfg.user;
        };
        "nextcloud/spreed/hashkey" = {
          owner = spreedCfg.user;
        };
        "nextcloud/spreed/blockkey" = {
          owner = spreedCfg.user;
        };
        "nextcloud/spreed/internalsecret" = {
          owner = spreedCfg.user;
        };
        "nextcloud/spreed/backendsecret" = {
          owner = spreedCfg.user;
        };
      };

      imports = [
        "${
          fetchTarball {
            url = "https://github.com/onny/nixos-nextcloud-testumgebung/archive/c3fdbf165814d403a8f8e81ff8e15adcbe7eadd0.tar.gz";
            sha256 = "sha256:19w6m1k4a0f48k1mnvdjkvcc8cnrlqg65kvyqzhxpkp5dbph9nzg";
          }
        }/nextcloud-extras.nix"
      ];

      services.postgresql = {
        enable = true;
        ensureUsers = [
          {
            name = "nextcloud";
            ensureDBOwnership = true;
          }
        ];
        ensureDatabases = [
          "nextcloud"
        ];
      };

      # Disable Other login method for nextcloud
      # Admin can login through adding `?direct=1` to url param
      systemd.services.nextcloud-config-oidc =
        let
          inherit (config.services.nextcloud) occ;
        in
        {
          wantedBy = [ "multi-user.target" ];
          after = [
            "nextcloud-setup.service"
          ];
          script = ''
            ${occ}/bin/nextcloud-occ config:app:set --type=string --value=0 user_oidc allow_multiple_user_backends
          '';
          serviceConfig = {
            Type = "oneshot";
          };
        };

      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud34;
        configureRedis = true;
        hostName = hostname;
        https = true;
        enableImagemagick = true;

        extraApps = {
          inherit (config.services.nextcloud.package.packages.apps)
            contacts
            calendar
            tasks
            whiteboard
            user_oidc
            memories
            music
            spreed
            ;

          camerarawpreviews = pkgs.fetchNextcloudApp {
            url = "https://github.com/ariselseng/camerarawpreviews/releases/download/v1.1.1/camerarawpreviews_nextcloud.tar.gz";
            sha256 = "sha256-PWX7WPJKoMIy4Kn6IH/+6UxPQ4G/nxuDNV1nNaGMp1s=";
            license = "agpl3Plus";
          };

          cospend = pkgs.fetchNextcloudApp {
            url = "https://github.com/julien-nc/cospend-nc/releases/download/v4.0.2/cospend-4.0.2.tar.gz";
            sha256 = "sha256-3uphQHtKlW8kXeLA5hMDpT14lEf+tnJyy4hfKioBDSw=";
            license = "agpl3Plus";
          };
        };
        extraAppsEnable = true;

        secrets = {
          mail_smtppassword = secrets."nextcloud/smtpPassword".path;
        };

        database.createLocally = true;
        config = {
          adminpassFile = secrets."nextcloud/adminPassword".path;
          dbtype = "pgsql";
        };

        settings = {
          # ==== Mail ==== #
          mail_smtpauth = true;
          mail_smtphost = mailserver.hostname;
          mail_smtpname = "nextcloud";
          mail_smtpmode = "smtp";
          mail_smtpauthtype = "LOGIN";
          mail_domain = "${domain}";
          mail_smtpport = 465;
          mail_smtpsecure = "ssl";
          mail_from_address = "nextcloud";

          allow_local_remote_servers = true;
          log_type = "syslog";
          trusted_proxies = [
            dn-cc.ip
            gcp.ip
          ];
          trusted_domains = [ hostname ];
          enabledPreviewProviders = [
            "OC\\Preview\\BMP"
            "OC\\Preview\\GIF"
            "OC\\Preview\\JPEG"
            "OC\\Preview\\Krita"
            "OC\\Preview\\MarkDown"
            "OC\\Preview\\MP3"
            "OC\\Preview\\OpenDocument"
            "OC\\Preview\\PNG"
            "OC\\Preview\\TXT"
            "OC\\Preview\\XBitmap"
            "OC\\Preview\\HEIC"
            "OC\\Preview\\SVG"
            "OC\\Preview\\FONT"
            "OC\\Preview\\Movie"
          ];
        };
      };

      services.nextcloud-whiteboard-server = mkIf config.services.nextcloud.enable {
        enable = true;
        settings = {
          NEXTCLOUD_URL = endpoint;
          PORT = "3002";
        };
        secrets = [
          secrets."nextcloud/whiteboard".path
        ];
      };

      environment.systemPackages = with pkgs; [
        exiftool
      ];

      # ==== Nextcloud Talk ==== #
      services.nextcloud-spreed-signaling = {
        enable = true;
        configureNginx = true;
        hostName = talk.hostname;
        backends.default = {
          urls = [ endpoint ];
          secretFile = secrets."nextcloud/spreed/backendsecret".path;
        };

        settings = {
          http.listen = "127.0.0.1:31008";
          turn = {
            servers = [ "turn:${coturn.hostname}:3478?transport=udp" ];
            secretFile = secrets."nextcloud/spreed/turnPassword".path;
            apikeyFile = secrets."nextcloud/spreed/turnSecret".path;
          };
          clients.internalsecretFile = secrets."nextcloud/spreed/internalsecret".path;
          sessions = {
            hashkeyFile = secrets."nextcloud/spreed/hashkey".path;
            blockkeyFile = secrets."nextcloud/spreed/blockkey".path;
          };
          nats.url = [ "nats://127.0.0.1:4222" ];
        };
      };

      services.nats = {
        enable = true;
        settings = {
          host = "127.0.0.1";
        };
      };

      services.nginx.virtualHosts.${hostname} = {
        useACMEHost = domain;
        forceSSL = true;

        locations."/whiteboard/" = {
          proxyWebsockets = true;
          proxyPass = "http://127.0.0.1:${config.services.nextcloud-whiteboard-server.settings.PORT}/";
        };
      };

      services.nginx.virtualHosts.${spreedCfg.hostName} = {
        useACMEHost = domain;
        forceSSL = true;
      };

      # ==== Secruity ==== #
      services.fail2ban = {
        jails = {
          nextcloud.settings = {
            backend = "systemd";
            journalmatch = "SYSLOG_IDENTIFIER=Nextcloud";
            enabled = true;
            port = 443;
            protocol = "tcp";
            filter = "nextcloud";
            maxretry = 3;
            bantime = 86400;
            findtime = 43200;
          };
        };
      };

      environment.etc = {
        "fail2ban/filter.d/nextcloud.local".text = mkDefault (mkAfter ''
          [Definition]
          failregex = ^.*"remoteAddr":"(?P<host><HOST>)".*"message":"Login failed:
                      ^.*"remoteAddr":"(?P<host><HOST>)".*"message":"Two-factor challenge failed:
                      ^.*"remoteAddr":"(?P<host><HOST>)".*"message":"Trusted domain error
        '');
      };
    };

}
