{
  ip,
  prefix,
  gateway,
  username,
  permitRootLogin ? "yes",
}:
{ pkgs, lib, ... }:
let
  inherit (lib) mkForce;
in
{
  # ==== Networking ==== #
  networking = {
    firewall.allowedTCPPorts = [ 22 ];
    useNetworkd = true;
  };

  boot.kernelParams = [ "ipv6.disable=1" ];

  services.resolved.enable = true;

  systemd.network.networks."10-wan" = {
    matchConfig.Type = "ether";

    address = [ "${ip}/${toString prefix}" ];
    gateway = [ gateway ];

    dns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  services.openssh = {
    enable = true;
    ports = mkForce [ 22 ];
    settings = {
      PasswordAuthentication = mkForce false;
      AllowUsers = mkForce [ username ];
      UseDns = mkForce false;
      PermitRootLogin = mkForce permitRootLogin;
    };
  };

  systemd.services.sshd.wantedBy = mkForce [ "multi-user.target" ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
  ];
}
