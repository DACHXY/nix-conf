{
  flake.modules.nixos.gui =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        wineWow64Packages.waylandFull
        winetricks
      ];
    };
}
