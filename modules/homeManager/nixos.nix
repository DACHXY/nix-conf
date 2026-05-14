{ inputs, config, ... }:
{
  flake.modules.nixos = {
    base = nixosArgs: {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        users.${nixosArgs.config.my.user.name}.imports = [
          config.flake.modules.homeManager.base

          (
            { osConfig, ... }:
            {
              home.stateVersion = osConfig.system.stateVersion;
            }
          )
        ];
      };
    };

    gui = nixosArgs: {
      imports = with config.flake.modules.nixos; [ noctalia ];
      home-manager.users.${nixosArgs.config.my.user.name}.imports = [
        config.flake.modules.homeManager.gui
      ];
    };
  };
}
