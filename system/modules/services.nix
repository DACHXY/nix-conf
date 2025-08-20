{
  lib,
  pkgs,
  username,
  ...
}:

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
        AllowUsers = lib.mkDefault [ username ];
        UseDns = lib.mkDefault false;
        PermitRootLogin = lib.mkDefault "no";
      };
    };

    xserver = {
      enable = false;
      xkb = {
        layout = "us";
        options = "caps:swapescape";
      };
    };
  };
}
