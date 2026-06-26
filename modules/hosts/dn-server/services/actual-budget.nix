{ config, ... }:
let
  globalConfig = config;
in
{
  configurations.nixos.dn-server.module =
    { config, ... }:
    let
      inherit (globalConfig.flake.public.config.services.actual) hostname endpoint;
      inherit (globalConfig.flake.public.config) domain;
      inherit (globalConfig.flake.public.config.services.oidc) oidcConfigEndpoint;
      inherit (config.sops) secrets;
    in
    {
      sops.secrets."actual/clientSecret" = {
        owner = "actual";
        group = "actual";
        mode = "640";
      };

      users.users.actual = {
        isSystemUser = true;
        group = "actual";
      };

      users.groups.actual = { };

      services = {
        actual = {
          enable = true;
          user = config.users.users.actual.name;
          group = config.users.users.actual.group;
          settings = {
            port = 31000;
            hostname = "127.0.0.1";
            serverFiles = "/var/lib/actual/server-files";
            userFiles = "/var/lib/actual/user-files";
            loginMethod = "openid";
            allowedLoginMethods = [ "openid" ];
            openId = {
              discoveryURL = oidcConfigEndpoint;
              client_id = "actual";
              client_secret._secret = secrets."actual/clientSecret".path;
              server_hostname = endpoint;
              authMethod = "openid";
            };
          };
        };
      };

      services.nginx.virtualHosts."${hostname}" = {
        forceSSL = true;
        useACMEHost = domain;

        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.actual.settings.port}";
          extraConfig = ''
            proxy_hide_header Cross-Origin-Embedder-Policy;
            proxy_hide_header Cross-Origin-Opener-Policy;
            add_header Cross-Origin-Embedder-Policy "require-corp" always;
            add_header Cross-Origin-Opener-Policy "same-origin" always;
            add_header Origin-Agent-Cluster "?1" always;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header Host $host;
          '';
        };
      };
    };
}
