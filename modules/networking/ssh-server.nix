{
  flake.modules.nixos.base =
    { config, lib, ... }:
    let
      username = config.my.user.name;
    in
    {
      networking.firewall.allowedTCPPorts = [ 22 ];

      services.openssh = {
        enable = true;
        ports = [ 22 ];
        settings = {
          PasswordAuthentication = lib.mkDefault false;
          AllowUsers = [ username ];
          UseDns = lib.mkDefault false;
          PermitRootLogin = lib.mkDefault "no";
        };
      };
    };
}
