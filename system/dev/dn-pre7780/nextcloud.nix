{
  config,
  pkgs,
  lib,
  ...
}:
let
  acmeWebRoot = "/var/www/${config.services.nextcloud.hostName}/html/";

  certScript = pkgs.writeShellScriptBin "certbot-nextcloud" ''
    REQUESTS_CA_BUNDLE=./system/extra/ca.crt
    ${pkgs.certbot}/bin/certbot certonly --webroot \
    --webroot-path ${acmeWebRoot} -v \
    -d ${config.services.nextcloud.hostName}\
    --server https://ca.net.dn:8443/acme/acme/directory \
    -m admin@mail.net.dn

    chown nginx:nginx -R /etc/letsencrypt
  '';
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
    authentication = lib.mkOverride 10 ''
      #type database  DBuser  origin-address  auth-method
      local all       all                     trust
    '';
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

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  users.groups.windows = {
    members = [ "nextcloud" ];
  };

  services.nextcloud = {
    enable = true;
    datadir = "/mnt/nextcloud";
    package = pkgs.nextcloud31;
    configureRedis = true;
    hostName = "pre7780.net.dn";
    https = true;

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        news
        contacts
        calendar
        tasks
        ;

      memories = pkgs.fetchNextcloudApp {
        sha256 = "sha256-BfxJDCGsiRJrZWkNJSQF3rSFm/G3zzQn7C6DCETSzw4=";
        url = "https://github.com/pulsejet/memories/releases/download/v7.5.2/memories.tar.gz";
        license = "agpl3Plus";
      };

      passwords =
        (pkgs.fetchNextcloudApp {
          sha256 = "sha256-Nu6WViFawQWby9CEEezAwoBNdp7O5O8a9IhDp/me/E0=";
          url = "https://git.mdns.eu/api/v4/projects/45/packages/generic/passwords/2025.2.0/passwords.tar.gz";
          license = "agpl3Plus";
        }).overrideAttrs
          (prev: {
            unpackPhase = ''
              cp $src passwords.tar.gz
              tar -xf passwords.tar.gz
              mv passwords/* ./
              rm passwords.tar.gz
              rm -r passwords
            '';
          });
    };
    extraAppsEnable = true;

    database.createLocally = true;
    config = {
      adminpassFile = config.sops.secrets."nextcloud/adminPassword".path;
      dbtype = "pgsql";
    };

    settings = {
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
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    exiftool
  ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      ${config.services.nextcloud.hostName} = {
        listen = lib.mkForce [
          {
            addr = "0.0.0.0";
            port = 443;
            ssl = true;
          }
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ];

        locations."^~ /.well-known/acme-challenge/" = {
          root = "/var/www/${config.services.nextcloud.hostName}/html";
          extraConfig = ''
            default_type "text/plain";
          '';
        };

        forceSSL = true;
        sslCertificate = "/etc/letsencrypt/live/${config.services.nextcloud.hostName}/fullchain.pem";
        sslCertificateKey = "/etc/letsencrypt/live/${config.services.nextcloud.hostName}/privkey.pem";

        extraConfig = ''
          ssl_protocols TLSv1.2 TLSv1.3;
          ssl_ciphers 'TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384';
          ssl_prefer_server_ciphers on;
        '';
      };
    };
  };
}
