{
  configurations.nixos.generic-desktop.module =
    { lib, modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = [
        "vmd"
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      # Intel CPU (dn-cscc is Intel). On AMD drop this line and use
      # hardware.cpu.amd.updateMicrocode instead.
      hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
    };
}
