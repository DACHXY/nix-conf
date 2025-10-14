{ config, ... }:
{
  imports = [
    (import ../expr/netbird.nix {
      domain = "pre7780.dn";
      coturnPassFile = config.sops.secrets."netbird/coturn/password".path;
      idpSecret = config.sops.secrets."netbird/oidc/secret".path;
      dataStoreEncryptionKey = config.sops.secrets."netbird/dataStoreKey".path;
    })
  ];
}
