{ config, ... }:
let
  globalConfig = config;
  inherit (globalConfig.flake.public.config) domain;
  inherit (globalConfig.flake.public.config.services) mailServer;
  inherit (globalConfig.flake.public.config.services.forgejo) hostname endpoint;

  oidcEndpoint = globalConfig.flake.public.config.services.oidc.endpoint;
in
{
  configurations.nixos.dn-server.module =
    { config, lib, ... }:
    let
      cfg = config.services.forgejo;
      srv = cfg.settings.server;

      forgejoOwner = {
        owner = "forgejo";
        mode = "400";
      };
    in
    {
      sops.secrets = {
        "forgejo/mailer/password" = forgejoOwner;
        "forgejo/server/secretKey" = forgejoOwner;
      };

      networking.firewall.allowedTCPPorts = [ srv.HTTP_PORT ];

      services.openssh.settings.AllowUsers = [ cfg.user ];

      systemd.services.forgejo.preStart =
        let
          adminCmd = "${lib.getExe cfg.package} admin user";
          pwd = config.sops.secrets."forgejo/mailer/password";
          user = "forgejo";
        in
        ''
          ${adminCmd} create --admin --email "noreply@${srv.DOMAIN}" --username ${user} --password "$(tr -d '\n' < ${pwd.path})" || true
        '';

      services.forgejo = {
        enable = true;
        database.type = "postgres";
        lfs.enable = true;

        settings = {
          server = {
            DOMAIN = hostname;
            ROOT_URL = endpoint;
            HTTP_PORT = 32006;
            SSH_PORT = lib.head config.services.openssh.ports;

            # ==== OpenID Connect ==== #
            ENABLE_OPENID_SIGNIN = true;
            WHITELISTED_URIS = "${oidcEndpoint}/*";
          };

          services.DISABLE_REGISTRATION = true;
          actions = {
            ENABLE = true;
            DEFAULT_ACTION_URL = "github";
          };

          mailer = {
            ENABLED = true;
            SMTP_ADDR = mailServer;
            SMTP_PORT = 587;
            FROM = "forgejo@${domain}";
            USER = "forgejo@${domain}";
          };
        };

        secrets = {
          mailer.PASSWD = config.sops.secrets."forgejo/mailer/password".path;
          server.SECRET_KEY = config.sops.secrets."forgejo/server/secretKey".path;
        };
      };

      services.nginx.virtualHosts.${hostname} = {
        useACMEHost = domain;
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:${toString srv.HTTP_PORT}";
      };
    };
}
