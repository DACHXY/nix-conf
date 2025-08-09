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

  home.packages = with pkgs; [
    libsForQt5.qtstyleplugin-kvantum
    libsForQt5.lightly
    libsForQt5.qt5ct
    adwaita-icon-theme
    gsettings-desktop-schemas
    glib
    (catppuccin-kvantum.override {
      accent = "lavender";
      variant = "macchiato";
    })
  ];

  qt = {
    enable = true;
    style.name = "qt5ct-style";
    style.package = pkgs.catppuccin-kvantum;
    platformTheme.name = "qtct";
  };

  xdg.configFile = {
    "Kvantum/catppuccin-macchiato-Lavender/catppuccin-macchiato-lavender/catppuccin-macchiato-lavender.kvconfig".source =
      "${pkgs.catppuccin-kvantum}/share/Kvantum/catppuccin-macchiato-lavender/cattpuccin-macchiato-lavender.kvconfig";
    "Kvantum/catppuccin-macchiato-Lavender/catppuccin-macchiato-lavender/catppuccin-macchiato-lavender.svg".source =
      "${pkgs.catppuccin-kvantum}/share/Kvantum/catppuccin-macchiato-lavender/cattpuccin-macchiato-lavender.svg";
  };
}
