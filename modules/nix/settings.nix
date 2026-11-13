{ lib, config, ... }:
{
  options.nix.settings =
    let
      strListOption = lib.mkOption {
        type = lib.types.listOf lib.types.singleLineStr;
        default = [ ];
      };
    in
    {
      keep-outputs = lib.mkOption { type = lib.types.bool; };
      experimental-features = strListOption;
      extra-system-features = strListOption;
      extra-substituters = strListOption;
      extra-trusted-public-keys = strListOption;
    };

  config = {
    nix.settings = {
      keep-outputs = true;
      experimental-features = [
        "nix-command"
        "flakes"
        "recursive-nix"
        "pipe-operators"
      ];
      extra-system-features = [ "recursive-nix" ];

      # Same caches as flake.nix's nixConfig, but in the system config: the
      # flake's nixConfig only applies to trusted users.
      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://noctalia.cachix.org"
        "https://yazi.cachix.org"
        "https://ghostty.cachix.org"
        "https://cache.numtide.com"
        "https://nix.unom.io"
      ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "punktfunk-cache-1:yhOJmHxzg6tzXpxSFzlYn6Pc6r0jHprsWqt8MZC654o="

        # Store-path signing keys of the deploying hosts (modules/nix/signing.nix),
        # so `nh os switch --target-host` works without trusted-users.
        "dn-cscc-1:TRBqT/iDnaZlhUVVUguwN7zoeJUWuodojWGr36mkyqM="
        "dn-workstation-1:J03OMrLrqnQfOT27HNWt2KJiUV5JU7g3nDEdnelKl6A="
      ];
    };
    flake.modules = {
      generic.base = {
        # A trusted user is root-equivalent (it can import unsigned store
        # paths and pick substituters), so only root is. Deploys to other
        # hosts are accepted through the signing keys above.
        nix.settings = config.nix.settings // {
          trusted-users = [ "root" ];
        };
      };

      # The system nix.conf already carries everything else; restricted
      # settings (keep-outputs, system-features, substituters, keys) in the
      # user nix.conf are ignored for untrusted users and only print warnings.
      homeManager.base = {
        nix.settings = {
          inherit (config.nix.settings) experimental-features;
        };
      };
    };
  };
}
