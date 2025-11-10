{
  adminPassFile,
  dbPassFile,
  dkimKey,
  ldapConf,
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

  logFilePath = "${config.services.stalwart-mail.dataDir}/logs";
  mkCondition = (
    condition: ithen: ielse: [
      {
        "if" = condition;
        "then" = ithen;
      }
      { "else" = ielse; }
    ]
  );
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

  systemd.tmpfiles.rules =
    let
      inherit (config.users.users.stalwart-mail) name group;
    in
    [
      "d ${logFilePath} 0750 ${name} ${group} - "
    ];

  services.stalwart-mail = {
    enable = true;
    openFirewall = true;
    settings = {
      server = {
        hostname = if (domain != null) then "mx1.${domain}" else config.networking.fqdn;
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
        hostname = "mx1.${domain}";
        domain = "${domain}";
      };
      acme."letsencrypt" = mkIf (acmeConf != null) acmeConf;

      directory = {
        "in-memory" = {
          type = "memory";
          principals = [
            {
              name = "postmaster";
              class = "individual";
              secret = "%{file:${adminPassFile}}%";
              email = [ "postmaster@${domain}" ];
            }
          ];
        };
        "ldap" = ldapConf;
        imap.lookup.domains = [
          domain
        ];
      };
      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:${adminPassFile}}%";
      };
      tracer."stdout" = {
        enable = true;
        type = "console";
        level = "info";
      };
    };
  };

  services.nginx = mkIf enableNginx {
    enable = true;
    virtualHosts = {
      "mail.${domain}" = {
        locations."/".proxyPass = "http://127.0.0.1:8080";
        locations."/jmap".proxyPass = "http://127.0.0.1:31004";
        enableACME = true;
        forceSSL = true;
      };
    };
  };
}
