{
  flake.modules.nixos.proxy-server =
    { config, ... }:
    {
      sops.secrets."_3proxy.passwd" = {
        mode = "440";
        owner = "_3proxy";
        group = "_3proxy";
      };

      users.users._3proxy = {
        isSystemUser = true;
        group = "_3proxy";
      };

      users.groups._3proxy = { };

      systemd.services."3proxy".serviceConfig = {
        User = "_3proxy";
        Group = "_3proxy";
      };

      services._3proxy = {
        enable = true;
        services = [
          {
            type = "socks";
            auth = [ "strong" ];
            acl = [
              {
                rule = "allow";
                users = [ "3proxy" ];
              }
            ];
          }
        ];
        usersFile = config.sops.secrets."_3proxy.passwd".path;
      };
    };
}
