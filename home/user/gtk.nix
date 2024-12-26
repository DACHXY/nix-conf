{ pkgs, ... }: {
  gtk = {
    enable = true;

    cursorTheme = {
      name = "Catppuccin-Macchiato-Lavender";
      package = pkgs.catppuccin-cursors.macchiatoLavender;
    };

    theme = {
      name = "Catppuccin-Macchiato-Compact-Lavender-dark";
      package = pkgs.catppuccin-gtk.override {
        size = "compact";
        accents = [ "lavender" ];
        variant = "macchiato";
      };
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-folders;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

  };
}
