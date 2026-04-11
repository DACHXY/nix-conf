{
  hostname,
  domain,
}:
{
  config,
  ...
}:
let
  inherit (config.sops) secrets;
  cfg = config.services.stalwart;
  secretPrefix = "/run/credentials/stalwart.service";
  adminPasswordVarName = "user_admin_password";
  adminPasswordFile = "${secretPrefix}/${adminPasswordVarName}";

  fqdn = "${hostname}.${domain}";
in
{
  sops.secrets."stalwart/password" = {
    owner = cfg.user;
    group = cfg.group;
    mode = "0440";
  };

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

  services.stalwart = {
    enable = true;
    stateVersion = "25.11";
    credentials = {
      user_admin_password = secrets."stalwart/password".path;
    };
    settings = {
      server = {
        hostname = fqdn;
        proxy = {
          trusted-networks = [ "10.0.0.148" ];
        };
        tls = {
          enable = true;
          implicit = true;
        };
        listener = {
          smtp = {
            protocol = "smtp";
            bind = "[::]:25";
            proxy_protocol = true;
          };
          submission = {
            protocol = "smtp";
            bind = "[::]:587";
            proxy_protocol = true;
          };
          submissions = {
            protocol = "smtp";
            bind = "[::]:465";
            tls.implicit = true;
            proxy_protocol = true;
          };
          imaps = {
            protocol = "imap";
            bind = "[::]:993";
            tls.implicit = true;
            proxy_protocol = true;
          };
          jmap = {
            bind = [ "10.0.0.130:31004" ];
            protocol = "http";
            proxy_protocol = true;
          };
          management = {
            protocol = "http";
            bind = [
              "10.0.0.130:8080"
              "127.0.0.1:8080"
            ];
            proxy_protocol = true;
          };
        };
      };

      lookup.default = {
        inherit domain;
        hostname = fqdn;
      };

      directory = {
        "in-memory" = {
          type = "memory";
          principals = [
            {
              name = "postmaster";
              class = "individual";
              secret = "%{file:${adminPasswordFile}}%";
              email = [ "postmaster@${domain}" ];
            }
          ];
        };
        imap.lookup.domains = [
          fqdn
        ];
      };

      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:${adminPasswordFile}}%";
      };
      tracer."stdout" = {
        enable = true;
        type = "console";
        level = "info";
      };
    };
  };
}
