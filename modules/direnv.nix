{
  flake.modules.generic.base = {
    programs.direnv = {
      enable = true;
      silent = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    environment.variables = {
      DIRENV_LOG_FORMAT = ""; # Hide direnv log
    };
  };
}
