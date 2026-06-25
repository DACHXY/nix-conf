{
  flake.modules.nixos.base =
    { config, ... }:
    let
      username = config.my.user.name;
    in
    {
      home-manager.users.${username} =
        { pkgs, config, ... }:
        let
          commonConfig = {
            extraConfig = {
              gtk-application-prefer-dark-theme = true;
            };
            theme = config.gtk.theme;
          };
        in
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

            gtk3 = commonConfig;
            gtk4 = commonConfig;
          };
        };
    };
}
