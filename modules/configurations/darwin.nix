{
  lib,
  config,
  inputs,
  withSystem,
  ...
}:
let
  inherit (lib)
    flip
    types
    mkOption
    mapAttrs
    mapAttrsToList
    mkMerge
    ;
in
{
  options.configurations.darwin = mkOption {
    type = types.lazyAttrsOf (
      types.submodule {
        options.module = mkOption {
          type = types.deferredModule;
        };
        options.system = mkOption {
          type = types.str;
        };
      }
    );
  };

  config.flake = {
    darwinConfigurations = flip mapAttrs config.configurations.darwin (
      name:
      { system, module }:
      inputs.nix-darwin.lib.darwinSystem {
        modules = [
          { system.stateVersion = 6; }
          module

          {
            nixpkgs = {
              hostPlatform = system;
              pkgs = withSystem system ({ pkgs, ... }: pkgs);
            };
          }
        ];
      }
    );

    checks =
      config.flake.darwinConfigurations
      |> mapAttrsToList (
        name: darwin: {
          ${darwin.config.nixpkgs.hostPlatform.system} = {
            "configurations/darwin/${name}" = darwin.config.system.build.toplevel;
          };
        }
      )
      |> mkMerge;
  };
}
