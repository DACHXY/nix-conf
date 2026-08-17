{ ... }:
{
  flake.modules.nixos.nvidia-gpu =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.xserver.videoDrivers = [ "nvidia" ];

      environment.systemPackages = with pkgs; [
        nvtopPackages.nvidia
        vulkan-tools
      ];

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
        nvidia.open = lib.mkDefault true;

        # For wayland
        nvidia.modesetting.enable = true;

        nvidia.powerManagement.enable = lib.mkDefault true;

        nvidia.nvidiaSettings = true;
        nvidia.dynamicBoost.enable = lib.mkDefault true;
        nvidia.package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.latest;

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

    };

  nixpkgs.config.allowUnfree = true;
}
