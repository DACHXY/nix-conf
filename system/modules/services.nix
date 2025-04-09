{ settings, ... }:

{
  networking = {
    firewall = {
      allowedTCPPorts = [
        22 # SSH
      ];
    };
  };

  services = {
    dbus.enable = true;
    openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = false;
        AllowUsers = [ settings.personal.username ];
        UseDns = true;
        PermitRootLogin = "no";
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
