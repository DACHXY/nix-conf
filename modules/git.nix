{
  flake.modules.homeManager.base = args: {
    programs.git = {
      enable = true;
      settings = {
        user.name = args.osConfig.my.user.name;
        user.email = args.osConfig.my.user.email;
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };
  };
}
