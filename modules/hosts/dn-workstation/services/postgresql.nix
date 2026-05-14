{
  configurations.nixos.dn-workstation.module = {
    services.postgresql = {
      enable = true;
      authentication = ''
        #type database      DBuser        origin-address  auth-method
        local all           all                           trust
      '';
    };
  };
}
