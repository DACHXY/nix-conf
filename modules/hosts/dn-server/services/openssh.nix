{
  configurations.nixos.dn-server.module = {
    networking.firewall.allowedTCPPorts = [ 30072 ];

    services.openssh.ports = [ 30072 ];
  };
}
