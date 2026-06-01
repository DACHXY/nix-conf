{ config, ... }:
{
  flake.modules.nixos.actual-budget =
    { ... }@nixosArgs:
    let
      inherit (config.flake.public.config.services.actual) hostname endpoint;
      inherit (config.flake.public.config) domain;
      inherit (config.flake.public.config.services.oidc) oidcConfigEndpoint;
      inherit (nixosArgs.config.sops) secrets;
    in
    {
      users.users.actual = {
        isSystemUser = true;
        group = "actual";
      };

      users.groups.actual = { };

      services = {
        actual = {
          enable = true;
          user = nixosArgs.config.users.users.actual.name;
          group = nixosArgs.config.users.users.actual.group;
          settings = {
            port = 31000;
            hostname = "127.0.0.1";
            serverFiles = "/var/lib/actual/server-files";
            userFiles = "/var/lib/actual/user-files";
          };
        };

        actual-budget-api = {
          enable = true;
          listenPort = 31001;
          listenHost = "127.0.0.1";
          serverURL = "https://${hostname}";
        };
      };

      sops.secrets."actual/clientSecret" = {
        owner = "actual";
        group = "actual";
        mode = "640";
      };

      imports = [
        (import ../../../modules/actual {
          fqdn = hostname;
        })
      ];

      services.nginx.virtualHosts."${hostname}" = {
        useACMEHost = domain;
      };

      services.actual.settings = {
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
}
