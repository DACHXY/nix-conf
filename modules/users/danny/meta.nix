{ config, ... }:
{
  flake.modules.generic.danny = args: {
    imports = [ config.flake.modules.generic.danny-keys ];

    home-manager.users.${args.config.my.user.name}.imports = [
      config.flake.modules.homeManager.danny
    ];

    my.user = {
      name = "danny";
      email = "dachxy@dnywe.com";
    };
  };
}
