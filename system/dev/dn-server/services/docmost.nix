{ config, ... }:
{
  imports = [
    (import ../../../modules/docmost.nix {
      fqdn = "docmost.net.dn";
      extraConf = {
        MAIL_DRIVER = "smtp";
      };
      envFile = config.sops.secrets."docmost".path;
    })
  ];
}
