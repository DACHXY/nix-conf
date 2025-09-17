{
  adminPassFile,
  dbPassFile,
  domain ? null,
  acmeConf ? null,
  enableNginx ? true,
}:
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "stalwart"
    ];
    ensureUsers = [
      {
        name = "stalwart";
        ensureDBOwnership = true;
      }
    ];
  };

  services.stalwart-mail = {
    enable = true;
    openFirewall = true;
    settings = {
      server = {
        hostname = if (domain != null) then "mx1.${domain}" else config.networking.fqdn;
        auto-ban.scan.rate = "1000/1d";
        tls = {
          enable = true;
          implicit = true;
        };
        listener = {
          smtp = {
            protocol = "smtp";
            bind = "[::]:25";
          };
          submissions = {
            protocol = "smtp";
            bind = "[::]:465";
            tls.implicit = true;
          };
          imaps = {
            protocol = "imap";
            bind = "[::]:993";
            tls.implicit = true;
          };
          management = {
            protocol = "http";
            bind = [ "127.0.0.1:8080" ];
          };
        };
      };
      lookup.default = {
        hostname = "mx1.${domain}";
        domain = "${domain}";
      };
      acme."step-ca" = mkIf (acmeConf != null) acmeConf;
      session.auth = {
        mechanisms = "[plain]";
        directory = "'in-memory'";
        require = true;
        allow-plain-text = true;
      };
      storage.data = "db";
      store."db" = {
        type = "postgresql";
        host = "localhost";
        port = 5432;
        database = "stalwart";
        user = "stalwart";
        password = "%{file:${dbPassFile}}%";
      };
      directory = {
        "imap".lookup.domains = [ domain ];
        "in-memory" = {
          type = "memory";
          principals = [
            {
              name = "admin";
              class = "admin";
              secret = "%{file:${adminPassFile}}%";
              email = [ "admin@${domain}" ];
            }
          ];
        };
      };
      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:${adminPassFile}}%";
      };
      tracer."stdout" = {
        enable = true;
        type = "console";
        level = "debug";
      };
    };
  };

  services.nginx = mkIf enableNginx {
    enable = true;
    virtualHosts = {
      "mail.${domain}" = {
        locations."/".proxyPass = "http://127.0.0.1:8080";
        enableACME = true;
        forceSSL = true;
      };
    };
  };
}
