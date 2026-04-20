{
  self,
  config,
  ...
}:
let
  inherit (config.systemConf) username;
  serverCfg = self.nixosConfigurations.dn-server.config;
  netbirdDomain = serverCfg.services.netbird.server.domain;
in
{
  users.users.${username}.extraGroups = [ "netbird-wt0" ];

  services.netbird = {
    clients.wt0 = {
      openFirewall = true;
      autoStart = true;
      port = 51820;
      environment = {
        NB_MANAGEMENT_URL = "https://${netbirdDomain}";
        NB_ADMIN_URL = "https://${netbirdDomain}";
      };
    };
  };
}
