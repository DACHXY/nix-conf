{ config, ... }:
{
  networking.firewall.allowedTCPPorts = [
    443
    80
  ];

  security.acme = {
    acceptTerms = true;
    defaults = {
      validMinDays = 2;
      server = "https://ca.net.dn/acme/acme/directory";
      renewInterval = "daily";
      email = "danny@net.dn";
      dnsProvider = "pdns";
      dnsPropagationCheck = false;
      # environmentFile = config.sops.secrets."acme/pdns".path;
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
