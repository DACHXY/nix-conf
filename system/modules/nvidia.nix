{
  nvidia-mode ? "sync",
  nvidia-bus-id,
  intel-bus-id,
  ...
}:
let
  validModes = [
    "offload"
    "sync"
    "rsync"
  ];
in
{
  config,
  pkgs,
  lib,
  ...
}:

# Nvidia offload mode
let
  validString = lib.concatStringsSep ", " validModes;

  offload = pkgs.writeShellScriptBin "offload" ''
    #!/bin/bash
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';
in
lib.checkListOfEnum "Nvidia Prime Mode" validModes [ nvidia-mode ] {
  environment.systemPackages = [ offload ];

  # Enable nvidia on wayland or xserver
  services.xserver.videoDrivers = [ "nvidia" ];

  boot.extraModprobeConfig = ''
    options nvidia_drm modeset=1 dbdev=1
  '';

  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  boot.kernelParams = [
    "nvidia-drm.fbdev=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  hardware = {
    nvidia.open = false;
    nvidia.modesetting.enable = true;

    nvidia.powerManagement.enable = true;
    nvidia.powerManagement.finegrained = true;

    nvidia.nvidiaSettings = true;
    nvidia.dynamicBoost.enable = true;
    nvidia.package = config.boot.kernelPackages.nvidiaPackages.beta;

    nvidia.prime =
      (
        # Reverse Sync Mode
        if nvidia-mode == "rsync" then
          {
            reverseSync.enable = true;
            allowExternalGpu = false;
          }
        # Offload mode
        else if nvidia-mode == "offload" then
          {
            offload = {
              enable = true;
              enableOffloadCmd = true;
            };
          }
        # Sync Mode
        else
          {
            sync.enable = true;
          }
      )
      // {
        intelBusId = intel-bus-id;
        nvidiaBusId = nvidia-bus-id;
      };

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
      ];
    };
  };

  environment.variables = {
    # GPU
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    MOZ_DISABLE_RDD_SANDBOX = 1;
  };
}
