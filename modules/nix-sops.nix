{ inputs, ... }:
{
  flake.modules.generic.base =
    { config, pkgs, ... }:
    let
      defaultSopsFile = ../. + "/modules/hosts/${config.networking.hostName}/secret.yaml";
      ageKeyFile = "/var/lib/sops-nix/key.txt";
    in
    {
      sops = {
        defaultSopsFile = defaultSopsFile;

        age = {
          keyFile = ageKeyFile;
        };
      };

      environment.variables = {
        SOPS_AGE_KEY_FILE = ageKeyFile;
      };

      environment.systemPackages = with pkgs; [ sops ];
    };

  flake.modules.nixos.base = {
    imports = [ inputs.sops-nix.nixosModules.sops ];
  };

  flake.modules.darwin.base = {
    imports = [ inputs.sops-nix.darwinModules.sops ];
  };

  flake.modules.homeManager.base =
    args:
    let
      defaultSopsFile = ../. + "/modules/hosts/${args.osConfig.networking.hostName}/secret.yaml";
      ageKeyFile = "/var/lib/sops-nix/key.txt";
    in
    {
      imports = [ inputs.sops-nix.homeManagerModules.default ];

      sops = {
        defaultSopsFile = defaultSopsFile;

        age = {
          keyFile = ageKeyFile;
        };
      };
    };
}
