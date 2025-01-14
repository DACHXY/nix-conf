{
  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };
  };

  home.sessionVariables = {
    DIRENV_LOG_FORMAT = ""; # Stop direnv log
  };
}
