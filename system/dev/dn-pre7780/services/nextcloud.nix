{
  config,
  lib,
  pkgs,
  ...
}:
let
  hostname = "drive.dnywe.com";
  port = 31007;
in
{
  imports = [
    (import ../../../modules/nextcloud.nix {
      configureACME = false;
      hostname = hostname;
      adminpassFile = config.sops.secrets."nextcloud/adminPassword".path;
      trusted-domains = [
        hostname
      ];
      trusted-proxies = [ "10.0.0.0/24" ];
      whiteboardSecrets = [
        config.sops.secrets."nextcloud/whiteboard".path
      ];
    })
  ];

  services.nextcloud = {
    https = lib.mkForce false;
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) spreed;

      twofactor_totp = pkgs.fetchNextcloudApp {
        url = "https://github.com/nextcloud-releases/twofactor_totp/releases/download/v6.4.1/twofactor_totp-v6.4.1.tar.gz";
        sha256 = "sha256-Wa2P6tpp75IxCsTG4B5DQ8+iTzR7yjKBi4ZDBcv+AOI=";
        license = "agpl3Plus";
      };

      twofactor_nextcloud_notification = pkgs.fetchNextcloudApp {
        url = "https://github.com/nextcloud-releases/twofactor_nextcloud_notification/releases/download/v3.9.0/twofactor_nextcloud_notification-v3.9.0.tar.gz";
        sha256 = "sha256-4fXWgDeiup5/Gm9hdZDj/u07rp/Nzwly53aLUT/d0IU=";
        license = "agpl3Plus";
      };

      twofactor_email = pkgs.fetchNextcloudApp {
        url = "https://github.com/nursoda/twofactor_email/releases/download/2.8.2/twofactor_email.tar.gz";
        sha256 = "sha256-zk5DYNwoIRTIWrchWDiCHuvAST2kuIoow6VaHAAzYog=";
        license = "agpl3Plus";
      };
    };
  };

  users.groups.signaling = {
  };

  users.users.signaling = {
    isSystemUser = true;
    group = "signaling";
  };

  systemd.services.nextcloud-spreed-signaling = {
    requiredBy = [
      "multi-users.target"
      "phpfpm-nextcloud.service"
    ];
    serviceConfig = {
      User = "signaling";
      Group = "signaling";
      ExecStart = "${lib.getExe' pkgs.nextcloud-spreed-signaling "server"} --config ${
        config.sops.secrets."nextcloud/signaling.conf".path
      }";
    };
  };

  services.nats = {
    enable = true;
    settings = {
      host = "127.0.0.1";
    };
  };

  services.nginx.virtualHosts."${hostname}".listen = lib.mkForce [
    {
      port = port;
      addr = "0.0.0.0";
    }
  ];
}
