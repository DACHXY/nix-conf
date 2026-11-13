{
  flake.modules.nixos.base =
    { config, ... }:
    let
      username = config.my.user.name;
    in
    {
      home-manager.users.${username} =
        {
          lib,
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
            gtk4 = commonConfig // {
              # Do not forward gtk.theme (adw-gtk3, a GTK3 theme) to GTK4:
              # libadwaita apps should use the system default plus an accent color.
              # This also adopts the new default from 26.05 onward, silencing the
              # legacy-default warning. stylix's HM gtk module sets this option too
              # (non-null), and null does not merge with a submodule, so mkForce wins.
              theme = lib.mkForce null;
            };
          };
        };
    };
}
