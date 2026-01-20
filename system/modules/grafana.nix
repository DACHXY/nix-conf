{
  passFile,
  smtpHost,
  smtpDomain,
  domain,
  extraSettings ? { },
  extraConf ? { },
}:
{ config, ... }:
let
  email = "grafana@${smtpDomain}";
in
{
  services.postgresql = {
    ensureDatabases = [ "grafana" ];
    ensureUsers = [
      {
        name = "grafana";
        ensureDBOwnership = true;
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = (
      {
        server = {
          http_addr = "127.0.0.1";
          http_port = 31003;
          root_url = "https://${domain}";
          domain = domain;
        };
        smtp = {
          enabled = true;
          user = "grafana";
          password = "$__file{${passFile}}";
          host = smtpHost;
          from_address = email;
          cert_file = config.security.pki.caBundle;
        };
        security = {
          admin_email = email;
          admin_password = "$__file{${passFile}}";
          secret_key = "$__file{${passFile}}";
        };
        database = {
          type = "postgres";
          user = "grafana";
          name = "grafana";
          host = "/var/run/postgresql";
        };
      }
      // extraSettings
    );

  }
  // extraConf;

  services.nginx.virtualHosts."${domain}" = {
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
    };
  };
}
