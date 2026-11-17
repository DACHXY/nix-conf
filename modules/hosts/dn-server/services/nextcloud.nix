{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services.nextcloud) hostname endpoint;
  inherit (config.flake.public.config.services) coturn mailserver talk;
  inherit (config.flake.public.config.machines) dn-cc gcp;
  # nixpkgs pins the signaling backend at 2.1.1. Talk 25 (the app that ships
  # with Nextcloud 35) authenticates its backend room requests in a way 2.1.1
  # rejects: every call to /api/v1/room/<token> comes back 403 and the server
  # logs "Failed attempt on BackendRoomAuth", so participants cannot be
  # authorised for calls. 2.2.0 is the release from the Nextcloud 35 era; drop
  # this overlay once `nixpkgs` is past 2.1.1.
  signalingOverlay = final: prev: {
    nextcloud-spreed-signaling = prev.nextcloud-spreed-signaling.overrideAttrs (old: {
      version = "2.2.0";
      src = final.fetchFromGitHub {
        owner = "strukturag";
        repo = "nextcloud-spreed-signaling";
        tag = "v2.2.0";
        hash = "sha256-xQrfvy96tSe3hm2cYKSMSN23o+VQJ59V9Ighd1FqM30=";
      };
      vendorHash = "sha256-U3V7RkyoKfdFlgIgkUi7nA1P9N1vXBgwHwCnC13RszQ=";
    });
  };
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
      # Applies to dn-server only: the one host that runs the signaling backend.
      nixpkgs.overlays = [ signalingOverlay ];

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
        # 34 is deprecated in NixOS 26.11; a major upgrade must go one step at a
        # time (34 -> 35). The pinned nixpkgs carries 35.0.2; 35.0.3 is the
        # current patch release. Drop the override once nixpkgs has >= 35.0.3.
        package = pkgs.nextcloud35.overrideAttrs (old: {
          version = "35.0.3";
          src = pkgs.fetchurl {
            url = "https://download.nextcloud.com/server/releases/nextcloud-35.0.3.tar.bz2";
            hash = "sha256-WEAUQM6Bt/jURajCqAJ1crYW74NZL5axIf0V7Ioa7TU=";
          };
        });
        configureRedis = true;
        hostName = hostname;
        https = true;
        enableImagemagick = true;

        extraApps = {
          # Already at the newest Nextcloud 35 release in the pinned nixpkgs.
          inherit (config.services.nextcloud.package.packages.apps)
            tasks
            onlyoffice
            ;

          # --- Apps nixpkgs pins behind the upstream app store ---------------
          # Newest stable release the app store lists for Nextcloud 35.0.3
          # (https://apps.nextcloud.com/api/v1/platform/35.0.3/apps.json). Bump
          # url + hash together (`nix store prefetch-file --json <url>`).
          contacts = pkgs.fetchNextcloudApp {
            url = "https://github.com/nextcloud-releases/contacts/releases/download/v8.10.0/contacts-v8.10.0.tar.gz";
            sha256 = "sha256-A12UMRXxKdIPuroZshJKDS9lpZw1yr4UJJW7auZQ1Uk=";
            license = "agpl3Plus";
          };

          calendar = pkgs.fetchNextcloudApp {
            url = "https://github.com/nextcloud-releases/calendar/releases/download/v6.6.5/calendar-v6.6.5.tar.gz";
            sha256 = "sha256-46+8KhDbh5IPU0cnlCNCJBEBBVCoCbKQLA6M8vJJIQc=";
            license = "agpl3Plus";
          };

          spreed = pkgs.fetchNextcloudApp {
            url = "https://github.com/nextcloud-releases/spreed/releases/download/v25.0.8/spreed-v25.0.8.tar.gz";
            sha256 = "sha256-5TbxSCa1iSwzJgjQcALdHjvcMuq8Wvg2g9RVmad/1I4=";
            license = "agpl3Plus";
          };

          whiteboard = pkgs.fetchNextcloudApp {
            url = "https://github.com/nextcloud-releases/whiteboard/releases/download/v2.1.2/whiteboard-v2.1.2.tar.gz";
            sha256 = "sha256-uj29Wz8aDTSvNoMFrHf9oGMwdFe4vRQ5Vcw1k9DO7r0=";
            license = "agpl3Plus";
          };

          user_oidc = pkgs.fetchNextcloudApp {
            url = "https://github.com/nextcloud-releases/user_oidc/releases/download/v8.13.0/user_oidc-v8.13.0.tar.gz";
            sha256 = "sha256-bxP6BHcUSmgS2GSGJsZM7pGAfR0LYMpBQkVDCGueJ3U=";
            license = "agpl3Plus";
          };

          music = pkgs.fetchNextcloudApp {
            url = "https://github.com/nc-music/music/releases/download/v3.3.1/nc-music-3.3.1.tar.gz";
            sha256 = "sha256-2NGl4SvetGMMggcchjur47rsBBaY7bt1tEW1Pj73Veo=";
            license = "agpl3Plus";
          };

          memories = pkgs.fetchNextcloudApp {
            url = "https://github.com/pulsejet/memories/releases/download/v11.1.4/memories.tar.gz";
            sha256 = "sha256-ObXsa/F1M0Qy6MQJoEhNqGb/+QPGNJQsyzxBgJ+QY1M=";
            license = "agpl3Plus";
          };

          camerarawpreviews = pkgs.fetchNextcloudApp {
            url = "https://github.com/ariselseng/camerarawpreviews/releases/download/v1.3.0/camerarawpreviews_nextcloud.tar.gz";
            sha256 = "sha256-SQ7bu80hoZimfxMjx/7h6fgSIF9NpZ9I0GdzqrXtZCU=";
            license = "agpl3Plus";
          };

          cospend = pkgs.fetchNextcloudApp {
            url = "https://github.com/julien-nc/cospend-nc/releases/download/v4.3.0/cospend-4.3.0.tar.gz";
            sha256 = "sha256-CGGseG4FcSWtkaTl+jgTFeXs6Ae6trMgs53LrZ6rb/0=";
            license = "agpl3Plus";
          };
        };
        extraAppsEnable = true;

        secrets = {
          mail_smtppassword = secrets."nextcloud/smtpPassword".path;
        };

        database.createLocally = true;
        config = {
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

      # cron.php runs with a minimal PATH. `occ maintenance:repair` and the
      # memories indexer shell out to `which`, `ps` and `exiftool`; without them
      # the repair step dies ("proc_open failed: which ps") and memories logs
      # "Indexing exception: binary path is empty".
      systemd.services.nextcloud-cron.path = with pkgs; [
        coreutils
        procps
        which
        exiftool
      ];

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
