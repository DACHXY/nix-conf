{
  ip,
  prefix,
  gateway,
}:
{ pkgs, ... }:
{
  # ==== Networking ==== #
  networking = {
    firewall.allowedTCPPorts = [ 22 ];
    useNetworkd = true;
  };

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

  services.openssh.enable = true;
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
  ];
}
