{
  config,
  ...
}:
let
  inherit (config.flake.public.config.ca) csrootca;
in
{
  flake.modules.nixos.danny =
    { ... }:
    {
      security.pki.certificateFiles = [
        # CSCC
        csrootca
      ];
    };
}
