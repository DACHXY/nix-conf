{
  pkgs,
  lib,
  self,
  config,
  ...
}:
let
  serverCfg = self.nixosConfigurations.dn-server.config;
  inherit (serverCfg.networking) domain;
  inherit (config.sops) secrets;
  inherit (lib) mkAfter getExe;

  matrixName = "matrix";
in
{
  sops.secrets."netbird/coturn/password" = {
    owner = "turnserver";
    sopsFile = ../../dn-server/sops/secret.yaml;
  };

  services.coturn.extraConfig = mkAfter ''
    user=${matrixName}:@${matrixName}-password@
  '';

  systemd.services.coturn.preStart = mkAfter ''
    ${getExe pkgs.replace-secret} @${matrixName}-password@ ${
      secrets."netbird/coturn/password".path
    } /run/coturn/turnserver.cfg
  '';

  services.netbird.server.coturn = {
    domain = "coturn.${domain}";
    enable = true;
    passwordFile = secrets."netbird/coturn/password".path;
    useAcmeCertificates = true;
  };
}
