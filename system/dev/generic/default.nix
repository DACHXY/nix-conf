{
  modulesPath,
  lib,
  pkgs,
  nix-version,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disk.nix
    ./hardware-configuration.nix
    ../../modules/nixsettings.nix
  ];

  boot.loader.systemd-boot.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.firewall = {
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
  };

  services.openssh = {
    enable = true;
    ports = [
      22
    ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
      UseDns = false;
    };
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn''
  ];

  system.stateVersion = nix-version;
}
