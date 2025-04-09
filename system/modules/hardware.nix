{
  pkgs,
  inputs,
  system,
  ...
}:

let
  pkgs-hyprland = inputs.hyprland.inputs.nixpkgs.legacyPackages.${system};
in
{
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      package32 = pkgs-hyprland.pkgsi686Linux.mesa;
      package = pkgs-hyprland.mesa;
      extraPackages = with pkgs; [
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

  security.polkit.enable = true;
}
