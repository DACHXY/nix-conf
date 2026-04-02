{
  self,
  config,
  ...
}:
let
  serverCfg = self.nixosConfigurations.dn-server.config;
  inherit (serverCfg.networking) domain;
  inherit (config.sops) secrets;
in
{
  sops.secrets."netbird/coturn/password" = {
    owner = "turnserver";
    sopsFile = ../../dn-server/sops/secret.yaml;
  };

  services.netbird.server.coturn = {
    domain = "coturn.${domain}";
    enable = true;
    passwordFile = secrets."netbird/coturn/password".path;
    useAcmeCertificates = true;
  };
}
