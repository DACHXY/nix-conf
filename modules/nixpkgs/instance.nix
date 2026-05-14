{
  lib,
  config,
  inputs,
  ...
}:
{
  options.nixpkgs = {
    config = {
      allowUnfree = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      allowUnfreePredicate = lib.mkOption {
        type = lib.types.functionTo lib.types.bool;
        default = _: false;
      };
      allowUnfreePackages = lib.mkOption {
        type = lib.types.listOf lib.types.singleLineStr;
        default = [ ];
      };
    };
    overlays = lib.mkOption {
      type = lib.types.listOf lib.types.unspecified;
      default = [ ];
    };
  };

  config = {
    perSystem =
      { system, ... }:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          inherit (config.nixpkgs) config overlays;
        };
      in
      {
        _module.args.pkgs = pkgs;
      };
  };
}
