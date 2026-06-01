{
  configurations.nixos.dn-server.module =
    {
      modulesPath,
      lib,
      config,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = [
        "vmd"
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      boot.initrd.kernelModules = [ "i915" ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
