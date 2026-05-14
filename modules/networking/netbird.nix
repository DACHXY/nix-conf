{ config, ... }:
{
  flake.modules.nixos.vpn =
    nixosArgs:
    let
      username = nixosArgs.config.my.user.name;
      netbirdEndpoint = config.flake.public.config.services.netbird.endpoint;
    in
    {
      users.users.${username}.extraGroups = [ "netbird-wt0" ];

      services.netbird.clients.wt0 = {
        openFirewall = true;
        autoStart = true;
        port = 51820;
        environment = {
          NB_MANAGEMENT_URL = netbirdEndpoint;
          NB_ADMIN_URL = netbirdEndpoint;
        };
      };
    };
}
