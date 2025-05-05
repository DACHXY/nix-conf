{
  config,
  pkgs,
  ...
}:
let
  mkProxyHost = (
    {
      domain,
      proxyPass,
      ssl ? false,
    }:
    (
      if ssl then
        {
          forceSSL = true;
          sslCertificate = "/etc/letsencrypt/live/${domain}/fullchain.pem";
          sslCertificateKey = "/etc/letsencrypt/live/${domain}/privkey.pem";

          listen = [
            {
              addr = "0.0.0.0";
              port = 443;
              ssl = true;
            }
          ];
        }
      else
        {
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
        }
    )
    // {
      locations."/" = {
        proxyPass = proxyPass;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        '';
      };

      locations."^~ /.well-known/acme-challenge/" = {
        root = "/var/www/${domain}/html";
        extraConfig = ''
          default_type "text/plain";
        '';
      };

      extraConfig = ''
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers 'TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384';
        ssl_prefer_server_ciphers on;
      '';
    }
  );

  certScript = pkgs.writeShellScriptBin "genCert" ''
    acmeWebRoot="/var/www/$1/html/";
    if [ ! -d "$acmeWebRoot"  ]; then
      mkdir -p "$acmeWebRoot"
    fi

    REQUESTS_CA_BUNDLE=${../../../system/extra/ca.crt} \
    ${pkgs.certbot}/bin/certbot certonly --webroot \
    --webroot-path $acmeWebRoot -v \
    -d "$1" \
    --server https://ca.net.dn:8443/acme/acme/directory \
    -m admin@mail.net.dn

    chown nginx:nginx -R /etc/letsencrypt
  '';

  pre7780 = {
    hostname = "pre-nextcloud.net.dn";
    ip = "10.0.0.130";
  };

  vaultwarden = {
    domain = "bitwarden.net.dn";
  };
in
{
  environment.systemPackages = [
    certScript
  ];

  services.nginx = {
    enable = true;
    enableReload = true;

    virtualHosts = {
      # Nextcloud - Server
      ${config.services.nextcloud.hostName} = {
        listen = [
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

      ${pre7780.hostname} = mkProxyHost {
        domain = pre7780.hostname;
        proxyPass = "http://${pre7780.ip}";
        ssl = true;
      };

      ${vaultwarden.domain} = mkProxyHost {
        domain = vaultwarden.domain;
        proxyPass = "http://127.0.0.1:${builtins.toString config.services.vaultwarden.config.ROCKET_PORT}";
        ssl = true;
      };
    };
  };
}
