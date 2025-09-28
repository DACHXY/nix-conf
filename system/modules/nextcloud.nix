{
  hostname,
  adminpassFile,
  datadir ? null,
  dataBackupPath ? null,
  dbBackupPath ? null,
  https ? true,
  configureACME ? true,
  trusted ? [ ],
}:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  enableBackup = dataBackupPath != null || dbBackupPath != null;

  nextcloudPkg = pkgs.nextcloud31.overrideAttrs (oldAttr: rec {
    caBundle = config.security.pki.caBundle;
    postPatch = ''
      cp ${caBundle} resources/config/ca-bundle.crt
    '';
  });
in
{
  imports = [
    "${
      fetchTarball {
        url = "https://github.com/onny/nixos-nextcloud-testumgebung/archive/fa6f062830b4bc3cedb9694c1dbf01d5fdf775ac.tar.gz";
        sha256 = "0gzd0276b8da3ykapgqks2zhsqdv4jjvbv97dsxg0hgrhb74z0fs";
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

  services.nextcloud = {
    enable = true;
    package = nextcloudPkg;
    configureRedis = true;
    hostName = hostname;
    https = if https then true else false;
    datadir = lib.mkIf (datadir != null) datadir;
    phpExtraExtensions =
      all: with all; [
        imagick
      ];

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        contacts
        calendar
        tasks
        whiteboard
        ;

      camerarawpreviews = pkgs.fetchNextcloudApp {
        url = "https://github.com/ariselseng/camerarawpreviews/releases/download/v0.8.7/camerarawpreviews_nextcloud.tar.gz";
        sha256 = "sha256-aiMUSJQVbr3xlJkqOaE3cNhdZu3CnPEIWTNVOoG4HSo=";
        license = "agpl3Plus";
      };

      user_oidc = pkgs.fetchNextcloudApp {
        url = "https://github.com/nextcloud-releases/user_oidc/releases/download/v7.2.0/user_oidc-v7.2.0.tar.gz";
        sha256 = "sha256-nXDWfRP9n9eH+JGg1a++kD5uLMsXh5BHAaTAOgLI9W4=";
        license = "agpl3Plus";
      };
    };
    extraAppsEnable = true;

    database.createLocally = true;
    config = {
      adminpassFile = adminpassFile;
      dbtype = "pgsql";
    };

    settings = {
      allow_local_remote_servers = true;
      log_type = "syslog";
      trusted_proxies = trusted;
      trusted_domains = trusted;
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
      ];
    };
  };

  services.nginx.virtualHosts.${hostname} = mkIf configureACME {
    enableACME = true;
    forceSSL = true;
  };

  environment.systemPackages = with pkgs; [
    exiftool
  ];

}
