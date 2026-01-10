{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (config.systemConf) username;
in
{
  networking = {
    firewall = {
      allowedTCPPorts = [
        22 # SSH
      ];
    };
  };

  services = {
    dbus = {
      enable = true;
      packages = [ pkgs.gcr ];
    };

    openssh = {
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
