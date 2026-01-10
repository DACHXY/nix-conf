{
  pkgs,
  inputs,
  config,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  wm =
    if config.programs.hyprland.enable then
      "hyprland"
    else if config.programs.niri.enable then
      "niri"
    else
      null;

  pkgs-wm = if wm != null then inputs.${wm}.inputs.nixpkgs.legacyPackages.${system} else pkgs;
in
{
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      package32 = pkgs-wm.pkgsi686Linux.mesa;
      package = pkgs-wm.mesa;
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

  security.polkit.enable = true;
}
