{
  configurations.nixos.dn-server.module =
    { config, ... }:
    let
      username = config.my.user.name;
    in
    {
      users.users.${username}.linger = true;
    };
}
