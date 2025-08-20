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
    gsettings-desktop-schemas
    glib
  ];
}
