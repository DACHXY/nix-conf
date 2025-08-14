{
  passFile,
  smtpHost,
  smtpDomain,
  domain,
  extraSettings ? { },
}:
{ config, ... }:
let
  email = "grafana@${smtpDomain}";
in
{
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
        };
      }
      // extraSettings
    );
  };

  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
    };
  };
}
