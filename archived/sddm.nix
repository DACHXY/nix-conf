{ self, ... }:
{
  flake.modules.nixos.gui =
    {
      pkgs,
      config,
      ...
    }:
    let
      inherit (self.lib) capitalize;
      username = config.my.user.name;
      sddmPackage = (
        pkgs.sddm-astronaut.override {
          embeddedTheme = "purple_leaves";
          themeConfig = {
            Font = "SF Pro Display Bold";
            HeaderText = "Welcome, ${capitalize username}";
          };
        }
      );
      sddmTheme = "sddm-astronaut-theme";
    in
    {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        theme = sddmTheme;
        settings.Theme.Current = sddmTheme;
      };

      environment.systemPackages = with pkgs.kdePackages; [
        sddmPackage
        qtmultimedia
        qtbase
        qtwayland
      ];
    };
}
