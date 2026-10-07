{
  inputs,
  ...
}:
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    let
      # Mesa >= 26.2.3 no longer advertises EGL_EXT_device_query in the glvnd
      # client extension string, which niri's DRM renderer init requires
      # (niri-wm/niri#2687). Without it niri cannot init its renderer on NVIDIA
      # and leaves a black screen / bare tty. Pin the graphics driver package to
      # the last good Mesa (26.2.0) from the nixpkgs-mesa input.
      mesaPinned = inputs.nixpkgs-mesa.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mesa;
    in
    {
      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
          package32 = pkgs.pkgsi686Linux.mesa;
          package = mesaPinned;
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
