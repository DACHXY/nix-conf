{
  self,
  config,
  ...
}:
let
  serverCfg = self.nixosConfigurations.dn-server.config;
  cfg = config.services.netbird;
  domain = serverCfg.services.netbird.server.domain;
in
{
  sops.secrets."netbird/wt0-setupKey" = {
    owner = cfg.clients.wt0.user.name;
    mode = "400";
  };

  services.netbird = {
    clients.wt0 = {
      openFirewall = true;
      autoStart = true;
      port = 51820;
      environment = {
        NB_MANAGEMENT_URL = "https://${domain}";
      };
      login = {
        enable = true;
        setupKeyFile = config.sops.secrets."netbird/wt0-setupKey".path;
      };
    };
  };
}
