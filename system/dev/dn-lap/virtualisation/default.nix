{
  imports = [
    ../../../modules/virtualization.nix
    ../../../modules/wine.nix
  ];

  virtualisation.vmware.host.enable = true;
}
