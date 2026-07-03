{
  flake.modules.homeManager.base = { ... }: {
    programs.jujutsu = {
      enable = true;
    };
  };
}
