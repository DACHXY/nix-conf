{ pkgs, ... }:

let
  themeConfig = {
    bgVidDay = "playlist/day.m3u";
    bgVidNight = "playlist/night.m3u";
  };
in
{
  services = {
    displayManager = {
      sddm.wayland.enable = true;
      sddm.enable = true;
      sddm.theme = "${pkgs.callPackage ./../../pkgs/sddm-themes/gruvbox.nix {
        inherit pkgs themeConfig;
      }}";
    };
  };

  environment.systemPackages = with pkgs; [
    # SDDM
    libsForQt5.qt5.qtmultimedia
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.qt5.qtsvg
    libsForQt5.qt5.qtwayland
    pkgs.gst_all_1.gst-libav
    pkgs.gst_all_1.gstreamer
    pkgs.gst_all_1.gst-plugins-good
  ];
}
