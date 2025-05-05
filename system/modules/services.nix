{
  settings,
  lib,
  pkgs,
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
        AllowUsers = lib.mkDefault [ settings.personal.username ];
        UseDns = lib.mkDefault true;
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
