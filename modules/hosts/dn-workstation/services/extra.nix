{ config, ... }:
{
  configurations.nixos.dn-workstation.module =
    let
      inherit (config.flake.public.config.services.forgejo) sshEndpoint;
      extra-modules = "${
        fetchGit {
          url = "${sshEndpoint}/dachxy/extra-modules.git";
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
