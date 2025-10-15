{ config, ... }:
{
  imports = [
    (import ../../../modules/nextcloud.nix {
      hostname = "nextcloud.net.dn";
      adminpassFile = config.sops.secrets."nextcloud/adminPassword".path;
      trusted-domains = [ "nextcloud.daccc.info" ];
      trusted-proxies = [ "10.0.0.0/24" ];
      whiteboardSecrets = [
        config.sops.secrets."nextcloud/whiteboard".path
      ];
    })
  ];
}
