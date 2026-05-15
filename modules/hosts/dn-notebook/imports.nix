{ config, ... }:
{
  configurations.darwin.dn-notebook.module = dwArgs: {
    imports = with config.flake.modules; [
      darwin.laptop
      darwin.danny
      darwin.nvf
      generic.dnywe
    ];

    home-manager.users.${dwArgs.config.my.user.name}.imports = with config.flake.modules.homeManager; [
      zed
    ];
  };
}
