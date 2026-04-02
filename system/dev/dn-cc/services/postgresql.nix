{ ... }:
{
  services.postgresql = {
    enable = true;
    authentication = ''
      #type database      DBuser        origin-address  auth-method
      local all           all                           trust
      host  all           all           127.0.0.1/32    trust
    '';
  };
}
