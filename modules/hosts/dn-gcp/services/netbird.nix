# Joins the NetBird overlay (self-hosted at netbird.dnywe.com) as
# dn-gcp.vnet.dn. Marking the peer as an exit node / network route peer is done in
# the NetBird dashboard, not here — the client only needs the setup key.
{ config, ... }:
let
  globalConfig = config;
in
{
  configurations.nixos.dn-gcp.module =
    {
      config,
      lib,
      ...
    }:
    {
      imports = with globalConfig.flake.modules.nixos; [
        vpn
      ];

      sops.secrets."netbird/setupKey" = {
        restartUnits = [ "netbird-wt0-login.service" ];
      };

      services.netbird.clients.wt0 = {
        ui.enable = lib.mkForce false;
        login = {
          enable = true;
          setupKeyFile = config.sops.secrets."netbird/setupKey".path;
        };
      };
    };
}
