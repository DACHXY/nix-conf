{ pkgs, xcursor-size, ... }:
let
  cursorName = "catppuccin-macchiato-lavender-cursors";
  themeName = "catppuccin-macchiato-lavender-compact";
  cursorSize = pkgs.lib.strings.toInt xcursor-size;
in
{
  gtk = {
    enable = true;

    cursorTheme = {
      name = cursorName;
      package = pkgs.catppuccin-cursors.macchiatoLavender;
      size = cursorSize;
    };

    theme = {
      name = themeName;
      package = pkgs.catppuccin-gtk.override {
        accents = [ "lavender" ];
        size = "compact";
        variant = "macchiato";
      };
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-folders;
    };

    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };

    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
    };
  };

  qt = {
    enable = true;
    style.name = "adwaita-dark";
    style.package = pkgs.adwaita-qt;
  };
}
