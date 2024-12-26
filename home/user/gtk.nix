{ pkgs, ... }:
{
  gtk = {
    enable = true;

    cursorTheme = {
      name = "Catppuccin-Macchiato-Lavender";
      package = pkgs.catppuccin-cursors.macchiatoLavender;
    };

    theme = {
      name = "catppuccin-macchiato-lavender-compact";
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
        gtk-application-prefer-dark-theme = 1;
      };
    };

    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };

  qt = {
    enable = true;
    style.name = "adwaita-dark";
    style.package = pkgs.adwaita-qt;
  };
}
