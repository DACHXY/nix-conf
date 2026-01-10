{ self, ... }:
let
  serverCfg = self.nixosConfigurations.dn-server.config;
  domain = serverCfg.services.netbird.server.domain;
in
{
  services.netbird = {
    clients.wt0 = {
      openFirewall = true;
      autoStart = true;
      port = 51820;
      environment = {
        NB_MANAGEMENT_URL = "https://${domain}";
      };
    };
  };
}
