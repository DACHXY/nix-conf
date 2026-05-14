{
  flake.modules.generic.base =
    { config, ... }:
    {
      users.users.${config.my.user.name} = {
      };
    };

  flake.modules.darwin.base =
    { config, ... }:
    {
      users.users.${config.my.user.name} = {
        home = "/Users/${config.my.user.name}";
      };
    };

  flake.modules.nixos.base =
    { config, ... }:
    {
      users.users.${config.my.user.name} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "input"
        ];
      };
    };
}
