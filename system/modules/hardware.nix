{ config, pkgs, nixpkgs, inputs, system, ... }:

let
  pkgs-unstable = inputs.hyprland.inputs.nixpkgs.legacyPackages.${system};
in
{
  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver =
      pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General = {
        experimental = true;
        Privacy = "device";
        JustWorksRepairing = "always";
        Class = "0x000100";
        FastConnectable = true;
      };
    };

    # Xbox controller
    xpadneo.enable = true;

    graphics = {
      enable = true;
      enable32Bit = true;
      package32 = pkgs-unstable.pkgsi686Linux.mesa.drivers;
      package = pkgs-unstable.mesa.drivers;
      extraPackages = with pkgs;
        [
          intel-media-driver # LIBVA_DRIVER_NAME=iHD
          vaapiVdpau
          (vaapiIntel.override {
            enableHybridCodec = true;
          })
          libvdpau-va-gl
        ];
    };

    enableRedistributableFirmware = true;
  };

  # Enable bluetooth
  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
    extraModprobeConfig = ''
      options bluetooth disable_ertm=Y
    '';
  };
}
