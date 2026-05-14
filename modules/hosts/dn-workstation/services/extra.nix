{ config, ... }:
{
  configurations.nixos.dn-workstation.module =
    let
      extra-modules = "${
        fetchGit {
          url = "ssh://${config.flake.public.config.services.forgejo.domain}/dachxy/extra-modules.git";
          rev = "e3b3f06ecaabe8ef4f4aebd7ebd5263e7adacb46";
          ref = "main";
        }
      }/modules/default.nix";
    in
    {
      imports = [
        extra-modules
      ];
    };
}
