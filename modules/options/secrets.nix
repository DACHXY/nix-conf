{ lib, ... }:
{
  flake.modules.generic.base = {
    options.my.secrets = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Declare this machine's sops-nix secrets.

          Set to false for a secret-free machine (no
          /var/lib/sops-nix/key.txt), e.g. a box you build from a fresh
          checkout where only the username is filled in. Every module that
          declares `sops.secrets` must honour this option.
        '';
      };
    };
  };
}
