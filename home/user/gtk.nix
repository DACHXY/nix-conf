{
  pkgs,
  xcursor-size,
  ...
}:
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

  home.packages = with pkgs; [
    libsForQt5.qtstyleplugin-kvantum
    libsForQt5.lightly
    libsForQt5.qt5ct
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
    "Kvantum/Catppuccin-Macchiato-Lavender/Catppuccin-Macchiato-Blue/Catppuccin-Macchiato-Blue.kvconfig".source =
      "${pkgs.catppuccin-kvantum}/share/Kvantum/Catppuccin-Macchiato-Lavender/Cattpuccin-Macchiato-Blue.kvconfig";
    "Kvantum/Catppuccin-Macchiato-Lavender/Catppuccin-Macchiato-Blue/Catppuccin-Macchiato-Blue.svg".source =
      "${pkgs.catppuccin-kvantum}/share/Kvantum/Catppuccin-Macchiato-Lavender/Cattpuccin-Macchiato-Blue.svg";
  };
}
