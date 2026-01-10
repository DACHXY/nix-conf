{ config, ... }:
{
  imports = [
    (import ../../../modules/crowdsec.nix {
      lapiCred = config.sops.secrets."crowdsec/lapi.yaml".path;
      capiCred = config.sops.secrets."crowdsec/capi.yaml".path;
      consoleToken = config.sops.secrets."crowdsec/consoleToken".path;
      enableServer = true;
      enablePrometheus = true;
    })
  ];
}
