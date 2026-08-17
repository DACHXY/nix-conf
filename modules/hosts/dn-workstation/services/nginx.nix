{
  configurations.nixos.dn-workstation.module = {
    networking.firewall.allowedTCPPorts = [
      443
      80
    ];

    users.users.nginx.extraGroups = [ "acme" ];

    services.nginx = {
      enable = true;
      enableReload = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      recommendedProxySettings = true;
    };
  };
}
