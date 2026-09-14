{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services) webmail;
in
{
  # jmapServerUrl must be reachable from the browser, not just this host -
  # the browser talks JMAP directly to Stalwart, so it points at
  # jmap.${domain} rather than the loopback management port.
  configurations.nixos.dn-server.module =
    { config, ... }:
    let
      # Must match managementPort in services/stalwart.nix.
      managementPort = 30093;
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
          # Bulwark's i18n middleware rewrites to an absolute URL built from
          # X-Forwarded-Proto + its own loopback port, then 500s fetching
          # that internally if the scheme is "https" (it only serves plain
          # HTTP there) - forced to "http" below. recommendedProxySettings
          # disabled since its own X-Forwarded-Proto header would otherwise
          # be appended after extraConfig and win.
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

      services.nginx.virtualHosts."${jmapHostname}" = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/".proxyPass = "http://127.0.0.1:${toString managementPort}";
      };

      # RFC 8620 autodiscovery: /.well-known/jmap 307s to a *relative*
      # "/jmap/session", so that path must be proxied here too even though
      # real JMAP traffic goes to jmap.${domain} - the session doc's own
      # apiUrl/downloadUrl/etc. point there, so nothing past /jmap/session
      # is needed on this vhost.
      services.nginx.virtualHosts."${domain}".locations = {
        "/.well-known/jmap".proxyPass = "http://127.0.0.1:${toString managementPort}/.well-known/jmap";
        "/jmap/".proxyPass = "http://127.0.0.1:${toString managementPort}/jmap/";
      };
    };
}
