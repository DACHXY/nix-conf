{ self, config, ... }:
let
  serverCfg = self.nixosConfigurations.dn-server.config;
  inherit (serverCfg.networking) domain;
in
{
  networking.firewall.allowedTCPPorts = [
    443
    80
  ];

  security.acme = {
    acceptTerms = true;
    defaults = {
      validMinDays = 2;
      webroot = null;
      server = "https://ca.${domain}/acme/acme/directory";
      renewInterval = "daily";
      email = "danny@pre7780.dn";
      dnsResolver = "10.0.0.1:53";
      dnsProvider = "pdns";
      dnsPropagationCheck = false;
      environmentFile = config.sops.secrets."acme/pdns".path;
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
