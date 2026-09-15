{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services) webmail;
in
{
  configurations.nixos.dn-server.module =
    { config, ... }:
    let
      jmapHostname = "jmap.${domain}";
    in
    {
      services.bulwark = {
        enable = true;
        hostname = "127.0.0.1";
        settings = {
          jmapServerUrl = "https://${jmapHostname}";
        };
      };

      services.nginx.virtualHosts."${webmail.hostname}" = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.bulwark.port}";
          recommendedProxySettings = false;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto http;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Server $hostname;
          '';
        };
      };
    };
}
