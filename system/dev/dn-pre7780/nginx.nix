{ ... }:
{
  security.acme = {
    acceptTerms = true;
    defaults = {
      validMinDays = 2;
      server = "https://10.0.0.1:${toString 8443}/acme/acme/directory";
      renewInterval = "daily";
      email = "danny@net.dn";
      webroot = "/var/lib/acme/acme-challenge";
    };
  };

  users.users.nginx.extraGroups = [ "acme" ];

  services.nginx = {
    enable = true;
    enableReload = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
  };
}
