{
  pkgs,
  ...
}:
let
  cursorName = "catppuccin-macchiato-lavender-cursors";
  themeName = "catppuccin-macchiato-lavender-compact";
in
{
  gtk = {
    enable = true;

    cursorTheme = {
      name = cursorName;
      package = pkgs.catppuccin-cursors.macchiatoLavender;
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
      package = pkgs.papirus-icon-theme;
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

  home.packages = with pkgs; [
    libsForQt5.qt5ct
    gsettings-desktop-schemas
    glib
  ];

  qt = {
    enable = true;
    style.name = "adwaita-dark";
    platformTheme.name = "gtk3";
  };
}
