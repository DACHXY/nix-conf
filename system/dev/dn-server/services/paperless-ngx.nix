{ config, ... }:
{
  imports = [
    (import ../../../modules/paperless-ngx.nix {
      domain = "paperless.net.dn";
      passwordFile = config.sops.secrets."paperless/adminPassword".path;
    })
  ];
}
