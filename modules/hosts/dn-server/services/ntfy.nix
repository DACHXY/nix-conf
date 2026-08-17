{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services.ntfy) hostname endpoint;
in
{
  configurations.nixos.dn-server.module =
    { config, ... }:
    let
      port = 31004;
    in
    {
      sops.secrets."ntfy" = {
        owner = config.services.ntfy-sh.user;
        mode = "0600";
      };

      services.ntfy-sh = {
        enable = true;
        settings = {
          listen-http = ":${toString port}";
          base-url = endpoint;
          upstream-base-url = "https://ntfy.sh";
          behind-proxy = true;
          proxy-trusted-hosts = "127.0.0.1";
          auth-default-access = "deny-all";
          enable-login = true;
          auth-file = "/var/lib/ntfy-sh/user.db";
          web-push-public-key = "BHN3E5Mwckakf6gOf2uAaiTueB-2L6i96QA1l0r1rSTX_N4qGtMgobmIgEfdY6LAFxradYLtRmwEzTzEnp_Xs5w";
          web-push-file = "/var/lib/ntfy-sh/webpush.db";
        };
        environmentFile = config.sops.secrets."ntfy".path;
      };

      services.nginx.virtualHosts = {
        "${hostname}" = {
          useACMEHost = domain;
          forceSSL = true;
          locations."/" = {
            proxyWebsockets = true;
            proxyPass = "http://127.0.0.1:${toString port}";
          };
        };
      };
    };
}
