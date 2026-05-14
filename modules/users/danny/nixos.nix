{ config, ... }:
{
  flake.modules.nixos.danny =
    { ... }@nixosArgs:
    {
      imports = [ config.flake.modules.generic.danny ];

      home-manager.users.${nixosArgs.config.my.user.name} = {
        imports = [ config.flake.modules.homeManager.danny ];
      };
    };
}
