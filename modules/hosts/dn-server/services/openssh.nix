{
  configurations.nixos.dn-server.module = {
    networking.firewall.allowedTCPPorts = [ 30072 ];

    services.openssh.ports = [ 30072 ];

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMT/rhCBp90SBW15dObrI1vl48uIdbjzwK+LQxtd/m8m danny@dn-workstation"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
    ];
  };
}
