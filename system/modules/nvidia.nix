{
  nvidia-mode ? "offload",
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
  offload = import ./offload.nix { inherit pkgs; };
in
lib.checkListOfEnum "Nvidia Prime Mode" validModes [ nvidia-mode ] {
  environment.systemPackages = [
    offload
    pkgs.nvtopPackages.nvidia
  ];

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
    nvidia.powerManagement.finegrained = if nvidia-mode == "sync" then false else true;

    nvidia.nvidiaSettings = true;
    nvidia.dynamicBoost.enable = true;
    nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

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
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    MOZ_DISABLE_RDD_SANDBOX = 1;
    OGL_DEDICATED_HW_STATE_PER_CONTEXT = "ENABLE_ROBUST";
    INTEL_GPU_MIN_FREQ_ON_AC = "500";
    # If multiple monitors are connected to dGPU & iGPU,
    # make sure to put the iGPU first
    # AQ_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
  };
}
