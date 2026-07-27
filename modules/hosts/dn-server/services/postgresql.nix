{
  configurations.nixos.dn-server.module = { lib, ... }: {
    services.postgresql = {
      enable = true;
      authentication = lib.mkBefore ''
        #type database      DBuser        origin-address  auth-method
        local all           all                           trust
      '';
    };
  };
}
