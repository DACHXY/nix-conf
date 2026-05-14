{
  flake.modules.homeManager.base = {
    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        aliases = {
          co = "pr checkout";
          pv = "pr view";
        };
      };
      gitCredentialHelper = {
        enable = true;
      };
    };
  };
}
