{
  flake.modules.homeManager.base =
    { lib, ... }@args:
    let
      inherit (lib) mkDefault;
    in
    {
      programs.git = {
        enable = true;
        settings = {
          user.name = mkDefault args.osConfig.my.user.name;
          user.email = mkDefault args.osConfig.my.user.email;
          init.defaultBranch = "main";
          pull.rebase = true;
        };
      };
    };
}
