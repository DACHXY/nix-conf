{
  flake.modules.nixos.base =
    { config, ... }:
    let
      username = config.my.user.name;
    in
    {
      home-manager.users.${username} =
        { pkgs, ... }:
        {
          gtk = {
            enable = true;

            cursorTheme = {
              name = "Nordzy-cursors";
              package = pkgs.nordzy-cursor-theme;
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
              theme = null;
            };
          };

          home.packages = with pkgs; [
            gsettings-desktop-schemas
            glib
          ];
        };
    };
}
