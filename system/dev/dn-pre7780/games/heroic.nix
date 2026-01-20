{ pkgs, ... }:
{
  home-manager.sharedModules = [
    {
      home.packages = with pkgs; [
        (heroic.override {
          extraPkgs = pkgs: [
            pkgs.gamemode
          ];
        })
      ];
    }
  ];
}
