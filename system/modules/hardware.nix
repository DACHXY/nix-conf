{ config, pkgs, nixpkgs, ... }:

{
  services.xserver.videoDrivers = ["nvidia"];

  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; } ;
  };

   environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; }; # Force intel-media-driver

  hardware = {
    bluetooth.enable = true;
    graphics = { 
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        libvdpau-va-gl
      ];
    };


    nvidia.open = false;
    nvidia.modesetting.enable = true;

    nvidia.powerManagement.enable = true;
    nvidia.powerManagement.finegrained = true;

    nvidia.nvidiaSettings = true;
    nvidia.dynamicBoost.enable = true;
    nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

    nvidia.prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
