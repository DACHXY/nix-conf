{
  configurations.nixos.dn-gcp.module =
    {
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      # e2-micro on GCE: virtio-blk / virtio-net / virtio-scsi only.
      boot.initrd.availableKernelModules = [
        "virtio_pci"
        "virtio_blk"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [
        "virtio_net"
        "virtio_balloon"
      ];
      boot.extraModulePackages = [ ];

      swapDevices = [ ];

      # 969MB of RAM: swap without a swapfile, never on the network path.
      zramSwap.enable = true;

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}
