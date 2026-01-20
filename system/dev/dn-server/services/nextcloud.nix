{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkDefault mkAfter;
  inherit (config.sops) secrets;
  inherit (config.networking) domain;
  spreedCfg = config.services.nextcloud-spreed-signaling;
  nextcloudCfg = config.services.nextcloud;
  turnDomain = "coturn.${domain}";
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
    (import ../../../modules/nextcloud.nix {
      hostname = "nextcloud.${domain}";
      adminpassFile = secrets."nextcloud/adminPassword".path;
      trusted-proxies = [ "10.0.0.0/24" ];
      whiteboardSecrets = [
        secrets."nextcloud/whiteboard".path
      ];
    })
  ];

  services.nextcloud = {
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) music spreed;

      user_migration = pkgs.fetchNextcloudApp {
        url = "https://github.com/nextcloud-releases/user_migration/releases/download/v9.0.0/user_migration-v9.0.0.tar.gz";
        sha256 = "sha256-WiEEAazuj8kh5o+URs22uoNWANXcXQYLTaoABMU6rFo=";
        license = "agpl3Plus";
      };

      cospend = pkgs.fetchNextcloudApp {
        url = "https://github.com/julien-nc/cospend-nc/releases/download/v3.2.0/cospend-3.2.0.tar.gz";
        sha256 = "sha256-mclcZDNmvpYX/2q7azyiTLSCiTYvk7ILeqtb/8+0ADQ=";
        license = "agpl3Plus";
      };
    };
    appstoreEnable = false;

    settings = {
      mail_smtpauth = true;
      mail_smtphost = "mx1.${domain}";
      mail_smtpname = "nextcloud";
      mail_smtpmode = "smtp";
      mail_smtpauthtype = "LOGIN";
      mail_domain = "${domain}";
      mail_smtpport = 465;
      mail_smtpsecure = "ssl";
      mail_from_address = "nextcloud";
    };

    secrets = {
      mail_smtppassword = secrets."nextcloud/smtpPassword".path;
    };
  };

  # ==== Nextcloud Talk ==== #
  services.nextcloud-spreed-signaling = {
    enable = true;
    configureNginx = true;
    hostName = "talk.${domain}";
    backends.default = {
      urls = [ "https://${nextcloudCfg.hostName}" ];
      secretFile = secrets."nextcloud/spreed/backendsecret".path;
    };

    settings = {
      http.listen = "127.0.0.1:31008";
      turn = {
        servers = [ "turn:${turnDomain}:3478?transport=udp" ];
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

  services.nats = mkIf nextcloudCfg.enable {
    enable = true;
    settings = {
      host = "127.0.0.1";
    };
  };

  services.nginx.virtualHosts.${nextcloudCfg.hostName} = {
    useACMEHost = domain;
    forceSSL = true;
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
}
