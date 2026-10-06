{ inputs, config, ... }:
{
  flake.modules.darwin = {
    base =
      darwinArgs:
      let
        hm = darwinArgs.config.home-manager.users.${darwinArgs.config.my.user.name};
      in
      {
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

        # Home Manager activation otherwise only runs during `darwin-rebuild
        # switch`, so anything an activation entry creates is missing until the
        # next switch. Run it again from launchd on every login.
        launchd.user.agents.home-manager-activation = {
          command = "${hm.home.activationPackage}/activate --driver-version 1";
          environment.HOME = hm.home.homeDirectory;
          serviceConfig.RunAtLoad = true;
        };
      };

    gui = darwinArgs: {
      home-manager.users.${darwinArgs.config.my.user.name}.imports = [
        config.flake.modules.homeManager.gui
      ];
    };
  };
}
