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
lib.checkListOfEnum "Nvidia Prime Mode" validModes [ nvidia-mode ] {
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
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
    nvidia.open = true;
    nvidia.modesetting.enable = true;

    nvidia.powerManagement.enable = true;
    nvidia.powerManagement.finegrained = if nvidia-mode == "sync" then false else true;

    nvidia.nvidiaSettings = true;
    nvidia.dynamicBoost.enable = true;
    nvidia.package =
      let
        base = config.boot.kernelPackages.nvidiaPackages.latest;
        cachyos-nvidia-patch = pkgs.fetchpatch {
          url = "https://raw.githubusercontent.com/CachyOS/CachyOS-PKGBUILDS/master/nvidia/nvidia-utils/kernel-6.19.patch";
          sha256 = "sha256-YuJjSUXE6jYSuZySYGnWSNG5sfVei7vvxDcHx3K+IN4=";
        };

        driverAttr = if config.hardware.nvidia.open then "open" else "bin";
      in
      base
      // {
        ${driverAttr} = base.${driverAttr}.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [ cachyos-nvidia-patch ];
        });
      };

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
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
  };

  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    GBM_BACKEND = "nvidia-drm";
    MOZ_DISABLE_RDD_SANDBOX = 1;
    OGL_DEDICATED_HW_STATE_PER_CONTEXT = "ENABLE_ROBUST";
  };
}
