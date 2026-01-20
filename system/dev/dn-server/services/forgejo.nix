{ lib, config, ... }:
let
  inherit (config.networking) domain;

  cfg = config.services.forgejo;
  srv = cfg.settings.server;
  hostname = "git.${domain}";
  mailServer = "mx1.net.dn";

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

  services.postgresqlBackup.databases = [ cfg.database.name ];

  systemd.services.forgejo.preStart =
    let
      adminCmd = "${lib.getExe cfg.package} admin user";
      pwd = config.sops.secrets."forgejo/mailer/password";
      user = "forgejo";
    in
    ''
      ${adminCmd} create --admin --email "noreply@${srv.DOMAIN}" --username ${user} --password "$(tr -d '\n' < ${pwd.path})" || true
    '';

  services.openssh.settings.AllowUsers = [ cfg.user ];

  services.forgejo = {
    enable = true;
    database.type = "postgres";
    lfs.enable = true;

    settings = {
      server = {
        DOMAIN = hostname;
        ROOT_URL = "https://${srv.DOMAIN}";
        HTTP_PORT = 32006;
        SSH_PORT = lib.head config.services.openssh.ports;

        # ==== OpenID Connect ==== #
        ENABLE_OPENID_SIGNIN = true;
        WHITELISTED_URIS = "https://${config.services.keycloak.settings.hostname}/*";
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
        FROM = "noreply@${srv.DOMAIN}";
        USER = "noreply@${srv.DOMAIN}";
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
}
