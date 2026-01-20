{ pkgs, ... }:
{
  home.packages = with pkgs; [ loupe ];

  xdg.mimeApps =
    let
      value = "org.gnome.Loupe.desktop";

      associations = builtins.listToAttrs (
        map
          (name: {
            inherit name value;
          })
          [
            "image/png"
            "image/jpeg"
            "image/gif"
            "image/bmp"
            "image/webp"
            "image/tiff"
            "image/svg+xml"
            "image/x-icon"
            "image/avif"
            "image/heif"
            "image/heic"
            "image/jxl"
            "image/apng"
            "image/x-raw"
            "image/x-xbitmap"
            "image/x-xpixmap"
            "image/x-portable-bitmap"
            "image/x-portable-graymap"
            "image/x-portable-pixmap"
            "image/x-tga"
            "image/x-pcx"
          ]
      );
    in
    {
      associations.added = associations;
      defaultApplications = associations;
    };
}
