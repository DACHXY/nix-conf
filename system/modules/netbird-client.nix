{
  self,
  config,
  ...
}:
let
  inherit (config.systemConf) username;
  serverCfg = self.nixosConfigurations.dn-server.config;
  domain = serverCfg.services.netbird.server.domain;
in
{
  users.users.${username}.extraGroups = [ "netbird-wt0" ];

  services.netbird = {
    clients.wt0 = {
      openFirewall = true;
      autoStart = true;
      port = 51820;
      environment = {
        NB_MANAGEMENT_URL = "https://${domain}";
        NB_ADMIN_URL = "https://${domain}";
      };
    };
  };
}
