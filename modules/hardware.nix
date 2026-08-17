{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
          package32 = pkgs.pkgsi686Linux.mesa;
          package = pkgs.mesa;
          extraPackages = with pkgs; [
            intel-media-driver # LIBVA_DRIVER_NAME=iHD
            libva-vdpau-driver
            (intel-vaapi-driver.override {
              enableHybridCodec = true;
            })
            libvdpau-va-gl
          ];
        };
        enableRedistributableFirmware = true;
      };
    };
}
