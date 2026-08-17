{
  flake.modules.nixos.base =
    { config, ... }:
    let
      username = config.my.user.name;
    in
    {
      home-manager.users.${username} =
        {
          pkgs,
          ...
        }:
        let
          commonConfig = {
            extraConfig = {
              gtk-application-prefer-dark-theme = true;
            };
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
