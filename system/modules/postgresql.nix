{ lib, ... }:
{
  services.postgresql = {
    enable = lib.mkDefault true;
    authentication = ''
      #type database      DBuser        origin-address  auth-method
      local all           all                           trust
    '';
  };
}
