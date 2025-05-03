{
  config,
  lib,
  pkgs,
  settings,
  devices,
  ...
}:
let
  acmeWebRoot = "/var/www/${config.services.nextcloud.hostName}/html/";

  certScript = pkgs.writeShellScriptBin "certbot-nextcloud" ''
    ${pkgs.certbot}/bin/certbot certonly --webroot \
    --webroot-path ${acmeWebRoot} -v \
    -d ${config.services.neextcloud.hostName} \
    --server https://ca.net.dn:8443/acme/acme/directory \
    -m admin@mail.net.dn

    chown nginx:nginx -R /etc/letsencrypt
  '';

  pre7780 = {
    hostname = "pre-nextcloud.net.dn";
    ip = "10.0.0.130";
  };
in
{
  services.nginx = {
    enable = true;
    enableReload = true;

    virtualHosts = {
      # Nextcloud - Server

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

      pre7780Hostname = {
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

        locations."/" = {
          proxyPass = "http://${pre7780.ip}/";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };

        locations."^~ /.well-known/acme-challenge/" = {
          root = "/var/www/${pre7780.hostname}/html";
          extraConfig = ''
            default_type "text/plain";
          '';
        };

        extraConfig = ''
          ssl_protocols TLSv1.2 TLSv1.3;
          ssl_ciphers 'TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384';
          ssl_prefer_server_ciphers on;
        '';

      };
    };
  };
}
