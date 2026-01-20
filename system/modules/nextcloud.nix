{
  hostname,
  adminpassFile,
  datadir ? null,
  https ? true,
  configureNginx ? true,
  trusted-domains ? [ ],
  trusted-proxies ? [ ],
  whiteboardSecrets ? [ ],
}:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf optionalString;
in
{
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

  systemd.services.nextcloud-config-recognize =
    let
      inherit (config.services.nextcloud) occ;
    in
    {
      wantedBy = [ "multi-user.target" ];
      after = [
        "nextcloud-setup.service"
      ];
      script = ''
        ${occ}/bin/nextcloud-occ config:app:set recognize node_binary --value '${lib.getExe pkgs.nodejs_22}'
        ${occ}/bin/nextcloud-occ config:app:set recognize tensorflow.purejs --value 'true'
      '';
      serviceConfig = {
        Type = "oneshot";
      };
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
    configureRedis = true;
    hostName = hostname;
    https = https;
    datadir = lib.mkIf (datadir != null) datadir;
    phpExtraExtensions =
      allEx: with allEx; [
        imagick
      ];

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        contacts
        calendar
        tasks
        whiteboard
        user_oidc
        memories
        recognize
        ;

      camerarawpreviews = pkgs.fetchNextcloudApp {
        url = "https://github.com/ariselseng/camerarawpreviews/releases/download/v0.8.8/camerarawpreviews_nextcloud.tar.gz";
        sha256 = "sha256-Pnjm38hn90oV3l4cPAnQ+oeO6x57iyqkm80jZGqDo1I=";
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
      trusted_proxies = trusted-proxies;
      trusted_domains = trusted-domains;
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

  services.nextcloud-whiteboard-server = mkIf config.services.nextcloud.enable {
    enable = true;
    settings = {
      NEXTCLOUD_URL = "http${optionalString https "s"}://${hostname}";
      PORT = "3002";
    };
    secrets = whiteboardSecrets;
  };

  services.nginx.virtualHosts.${hostname} = mkIf configureNginx {
    locations."/whiteboard/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:${config.services.nextcloud-whiteboard-server.settings.PORT}/";
    };
  };

  environment.systemPackages = with pkgs; [
    exiftool
  ];
}
