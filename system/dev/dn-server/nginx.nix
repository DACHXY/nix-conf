{
  config,
  ...
}:
{
  security.acme = {
    acceptTerms = true;
    defaults = {
      validMinDays = 2;
      server = "https://10.0.0.1:${toString config.services.step-ca.port}/acme/acme/directory";
      renewInterval = "daily";
      email = "danny@net.dn";
      dnsProvider = "pdns";
      dnsPropagationCheck = false;
      environmentFile = config.sops.secrets."acme/env".path;
    };
  };

  users.users.nginx.extraGroups = [ "acme" ];

  services.nginx = {
    enable = true;
    enableReload = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;

    virtualHosts = {
      "files.${config.networking.domain}" = {
        enableACME = true;
        forceSSL = true;

        root = "/var/www/files";
        locations."/" = {
          extraConfig = ''
            autoindex on;
            autoindex_exact_size off;
            autoindex_localtime on;
          '';
        };

        extraConfig = ''
          types {
            image/png png;
            image/jpeg jpg jpeg;
            image/gif gif;
          }
        '';
      };

      "webcam.net.dn" = {
        enableACME = true;
        forceSSL = true;

        locations."/ws/" = {
          proxyPass = "http://10.0.0.130:8080/";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };

        locations."/".proxyPass = "http://10.0.0.130:8001/phone.html";
      };

      "ca.net.dn" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "https://10.0.0.1:8443/";
        };
      };
    };
  };
}
