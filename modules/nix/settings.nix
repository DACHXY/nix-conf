{ lib, config, ... }:
{
  options.nix.settings = {
    keep-outputs = lib.mkOption { type = lib.types.bool; };
    experimental-features = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ ];
    };
    extra-system-features = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ ];
    };
  };

  config = {
    nix.settings = {
      keep-outputs = true;
      experimental-features = [
        "nix-command"
        "flakes"
        "recursive-nix"
        "pipe-operators"
      ];
      extra-system-features = [ "recursive-nix" ];
    };
    flake.modules = {
      generic.base = args: {
        nix.settings = config.nix.settings // {
          trusted-users = [
            "@wheels"
            args.config.my.user.name
          ];
        };
      };

      homeManager.base = hmArgs: {
        nix.settings = config.nix.settings // {
          trusted-users = [
            "@wheels"
            hmArgs.osConfig.my.user.name
          ];
        };
      };
    };
  };
}
