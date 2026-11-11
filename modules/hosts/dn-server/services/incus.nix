{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.machines) dn-cscc;
  hostname = "incus.${domain}";

  # Incus only authenticates clients by TLS certificate (`auth_methods: [tls]`),
  # and a browser's certificate cannot survive an HTTP proxy hop, so nginx has
  # to present a certificate of its own. `nginx-dn-server` is registered as a
  # trusted client on dn-cscc (`incus config trust list`, fingerprint
  # 700d89bfd9cb); the key lives in modules/config/incus-proxy.yaml.
  certSecret = "incus-proxy/cert";
  keySecret = "incus-proxy/key";
in
{
  configurations.nixos.dn-server.module =
    { config, ... }:
    {
      sops.secrets.${certSecret} = {
        sopsFile = ../../../config/incus-proxy.yaml;
        mode = "0440";
        group = "nginx";
        restartUnits = [ "nginx.service" ];
      };
      sops.secrets.${keySecret} = {
        sopsFile = ../../../config/incus-proxy.yaml;
        mode = "0440";
        group = "nginx";
        restartUnits = [ "nginx.service" ];
      };

      # Access policy lives with the other vhosts in
      # modules/hosts/dn-server/services/nginx.nix (mkDenyConfig); this only
      # fills in the upstream, which sits on dn-cscc behind WireGuard.
      services.nginx.virtualHosts.${hostname} = {
        useACMEHost = domain;
        forceSSL = true;

        locations."/" = {
          proxyPass = "https://${dn-cscc.wg.wg0.ip}:8443";
          proxyWebsockets = true;

          extraConfig = ''
            # Incus serves HTTPS with its own (self-signed) certificate.
            proxy_ssl_server_name on;
            proxy_ssl_verify off;

            # Client certificate: without it every request is `untrusted` and
            # the API answers 403.
            proxy_ssl_certificate ${config.sops.secrets.${certSecret}.path};
            proxy_ssl_certificate_key ${config.sops.secrets.${keySecret}.path};

            # Image uploads go through the API; the global 40m limit is too
            # small for anything but tiny containers.
            client_max_body_size 0;

            # /1.0/events and instance consoles are long-lived streams.
            proxy_buffering off;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;

            # Host / X-Forwarded-* come from recommendedProxySettings; setting
            # them here again sends each header twice, and Go's net/http (Incus)
            # rejects a request with two Host headers as 400 Bad Request.
          '';
        };
      };
    };
}
