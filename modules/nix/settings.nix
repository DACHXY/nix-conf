{ lib, config, ... }:
{
  options.nix.settings =
    let
      strListOption = lib.mkOption {
        type = lib.types.listOf lib.types.singleLineStr;
        default = [ ];
      };
    in
    {
      keep-outputs = lib.mkOption { type = lib.types.bool; };
      experimental-features = strListOption;
      extra-system-features = strListOption;
      extra-substituters = strListOption;
      extra-trusted-public-keys = strListOption;
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
