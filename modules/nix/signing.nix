{ lib, ... }:
let
  # Hosts that build and push closures with `nh os switch --target-host`.
  # Each has a root-only key at /var/lib/nix-signing/key.sec, created with
  #   nix key generate-secret --key-name <host>-1
  # and its public half listed in modules/nix/settings.nix.
  signers = [
    "dn-cscc"
    "dn-workstation"
  ];
in
{
  flake.modules.nixos.base =
    { config, ... }:
    {
      # The daemon signs every path it builds, so targets accept them from an
      # untrusted user.
      nix.settings.secret-key-files = lib.mkIf (builtins.elem config.networking.hostName signers) [
        "/var/lib/nix-signing/key.sec"
      ];
    };
}
