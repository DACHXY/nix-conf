{
  imports = [
    ../../../modules/virtualization.nix
    ../../../modules/wine.nix
    # ./kvm.nix
  ];

  virtualisation.vmware.host.enable = true;
}
