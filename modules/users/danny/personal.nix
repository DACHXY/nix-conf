{ config, ... }:
{
  # generic.danny-personal: danny's personal credentials (GitHub token,
  # kubeconfig, ...) for the machines he works at -- the desktops and the Mac,
  # never dn-server / dn-cc. Their secrets live in ./secret.yaml, whose
  # recipients are only those machines (see .sops.yaml).
  flake.modules.nixos.danny-gui.imports = [ config.flake.modules.generic.danny-personal ];
  flake.modules.darwin.danny.imports = [ config.flake.modules.generic.danny-personal ];
}
