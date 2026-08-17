{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  flake.modules.generic.base = {
    options.my.user = mkOption {
      type = types.submodule {
        options = {
          name = mkOption {
            type = types.str;
          };
          email = mkOption {
            type = types.str;
          };
        };
      };
    };
  };
}
