{ pkgs, ... }:
{
  home-manager.sharedModules = [
    {
      home.packages = with pkgs; [
        lsfg-vk
        lsfg-vk-ui
      ];
    }
  ];
}
