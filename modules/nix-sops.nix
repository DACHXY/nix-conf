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

      # age-plugin-fido2-hmac: editing secrets uses the admin key on the
      # PicoKey (~/.config/sops/age/keys.txt, sops' default identity path).
      environment.systemPackages = with pkgs; [
        sops
        age-plugin-fido2-hmac
      ];
    };

  flake.modules.nixos.base = {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    # The host key decrypts every secret of this machine: root only. It is used
    # solely by sops-nix at activation; people edit with the PicoKey admin key.
    systemd.tmpfiles.rules = [
      "z /var/lib/sops-nix 0700 root root -"
      "z /var/lib/sops-nix/key.txt 0600 root root -"
    ];
  };

  flake.modules.darwin.base = {
    imports = [ inputs.sops-nix.darwinModules.sops ];

    # nix-darwin hosts still edit and decrypt home-manager secrets with the
    # host key.
    environment.variables.SOPS_AGE_KEY_FILE = "/var/lib/sops-nix/key.txt";
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
