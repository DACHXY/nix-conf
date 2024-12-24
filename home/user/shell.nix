{ pkgs, ... }: {
  programs = {
    # nushell = {
    #   enable = true;
    #   configFile.source = ../config/nushell/config.nu;
    #   envFile.source = ../config/nushell/env.nu;
    # };

    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';
      plugins = [{
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
      # Other plugins can be located in config file
        ];
    };

    carapace = {
      enable = true;
      enableFishIntegration = true;
    };

    starship = {
      enable = true;
      enableFishIntegration = true;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
