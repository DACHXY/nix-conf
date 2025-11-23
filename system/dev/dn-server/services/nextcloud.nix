{ config, ... }:
{
  imports = [
    (import ../../../modules/nextcloud.nix {
      hostname = "nextcloud.net.dn";
      adminpassFile = config.sops.secrets."nextcloud/adminPassword".path;
      trusted-proxies = [ "10.0.0.0/24" ];
      whiteboardSecrets = [
        config.sops.secrets."nextcloud/whiteboard".path
      ];
    })
  ];

  services.nextcloud = {
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) music;
    };
  };
}
