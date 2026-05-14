{ ... }:
{
  flake.modules.generic.base = {
    home-manager = {
      useGlobalPkgs = true;
      overwriteBackup = true;
      extraSpecialArgs = {
        hasGlobalPkgs = true;
      };
      backupFileExtension = "hm-backup";
    };
  };
  flake.modules.homeManager.base =
    { osConfig, ... }:
    {
      home = {
        username = osConfig.my.user.name;
      };
      programs.home-manager.enable = true;
      programs.man.generateCaches = false;

      gtk.gtk4.theme = null;
    };
}
