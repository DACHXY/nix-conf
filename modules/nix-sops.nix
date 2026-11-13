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

  flake.modules.nixos.base =
    { lib, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      # NixOS hosts decrypt with their SSH host key (sops-nix's default
      # sshKeyPaths, /etc/ssh/ssh_host_ed25519_key, root-only); .sops.yaml
      # lists its ssh-to-age recipient. People edit with the PicoKey admin key.
      sops.age.keyFile = lib.mkForce null;

      # The old age key (/var/lib/sops-nix/key.txt) was readable by danny and
      # was rotated out of every secret file; remove it.
      systemd.tmpfiles.rules = [
        "z /var/lib/sops-nix 0700 root root -"
        "r /var/lib/sops-nix/key.txt"
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
