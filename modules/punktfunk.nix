{ inputs, ... }:
{
  flake.modules.nixos.punktfunk =
    { config, ... }:
    {
      imports = [ inputs.punktfunk.nixosModules.default ];

      services.punktfunk.host = {
        enable = true;
        desktopSession = true;
        openFirewall = true;
        users = [ config.my.user.name ];
        settings.PUNKTFUNK_MGMT_BIND = "0.0.0.0:47991";
      };

      # Native punktfunk/1 client + headless `punktfunk` CLI on this box.
      services.punktfunk.client.enable = true;

      networking.firewall.allowedTCPPorts = [ 47991 ];
    };
}
