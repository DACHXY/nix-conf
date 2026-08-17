{
  inputs,
  lib,
  config,
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
  options.configurations.nixos = mkOption {
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
    nixosConfigurations = flip mapAttrs config.configurations.nixos (
      name:
      { system, module }:
      inputs.nixpkgs.lib.nixosSystem {
        modules = [
          module

          {
            nixpkgs = {
              hostPlatform = system;
              pkgs = withSystem system ({ pkgs, ... }: pkgs);
            };
            system.stateVersion = "25.11";
          }
        ];
      }
    );

    checks =
      config.flake.nixosConfigurations
      |> mapAttrsToList (
        name: nixos: {
          ${nixos.config.nixpkgs.hostPlatform.system} = {
            "configurations/nixos/${name}" = nixos.config.system.build.toplevel;
          };
        }
      )
      |> mkMerge;
  };
}
