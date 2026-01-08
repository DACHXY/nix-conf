{ pkgs, ... }:
{
  home-manager.sharedModules = [
    {
      home.packages = with pkgs; [
        prismlauncher
        lsfg-vk
        lsfg-vk-ui
      ];
    }
  ];
}
