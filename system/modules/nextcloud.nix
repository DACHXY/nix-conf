{
  hostname,
  adminpassFile,
  datadir ? null,
  https ? true,
  configureACME ? true,
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

  nextcloudPkg = pkgs.nextcloud32.overrideAttrs (oldAttr: rec {
    caBundle = config.security.pki.caBundle;
    postPatch = ''
      cp ${caBundle} resources/config/ca-bundle.crt
    '';
  });

  # Patch for downloading models. Hardcoded to `/var/lib/nextcloud/models`
  recognize = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "recognize-patched";
    version = "10.0.4";

    src = pkgs.fetchNextcloudApp {
      url = "https://github.com/nextcloud/recognize/releases/download/v10.0.4/recognize-10.0.4.tar.gz";
      sha256 = "sha256-/RHnnvGJMcxe4EuceYc20xh3qkYy1ZzGsyvp0h03eLk=";
      license = "agpl3Plus";
    };

    patches = [
      ../../pkgs/patches/nextcloud_recognize_models_path.patch
    ];

    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  });

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

  services.nextcloud = {
    enable = true;
    package = nextcloudPkg;
    configureRedis = true;
    hostName = hostname;
    https = https;
    datadir = lib.mkIf (datadir != null) datadir;
    phpExtraExtensions =
      all: with all; [
        imagick
      ];

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        contacts
        calendar
        whiteboard
        user_oidc
        memories
        ;

      inherit recognize;

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

  services.nextcloud-whiteboard-server = {
    enable = true;
    settings = {
      NEXTCLOUD_URL = "http${optionalString configureACME "s"}://${hostname}";
      PORT = "3002";
    };
    secrets = whiteboardSecrets;
  };

  services.nginx.virtualHosts.${hostname} = mkIf configureACME {
    enableACME = true;
    forceSSL = true;
    locations."/whiteboard/" = {
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:${config.services.nextcloud-whiteboard-server.settings.PORT}/";
    };
  };

  environment.systemPackages = with pkgs; [
    exiftool
  ];
}
