{
  flake.modules.homeManager.base = {
    programs.nix-index = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
