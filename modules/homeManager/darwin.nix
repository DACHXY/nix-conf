{ inputs, config, ... }:
{
  flake.modules.darwin = {
    base = darwinArgs: {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      home-manager = {
        users.${darwinArgs.config.my.user.name}.imports = [
          config.flake.modules.homeManager.base

          {
            home.stateVersion = "26.05";
            home.enableNixpkgsReleaseCheck = false;
          }
        ];
      };
    };

    gui = darwinArgs: {
      home-manager.users.${darwinArgs.config.my.user.name}.imports = [
        config.flake.modules.homeManager.gui
      ];
    };
  };
}
