{ config, ... }:
{
  services.nginx = {
    enable = true;
    enableReload = true;

    virtualHosts = {
      ${config.services.nextcloud.hostName} = {
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ];

        extraConfig = ''
          ssl_protocols TLSv1.2 TLSv1.3;
          ssl_ciphers 'TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384';
          ssl_prefer_server_ciphers on;
        '';
      };
    };
  };
}
