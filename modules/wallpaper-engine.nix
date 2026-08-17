{ inputs, ... }:
{
  flake.modules.nixos.wallpaper-engine =
    { config, pkgs, ... }:
    let
      inherit (config.my.user) name;
    in
    {
      home-manager.users.${name} = {
        home.packages = with pkgs; [
          linux-wallpaperengine
          inputs.linux-wallpaper-engine.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
      };
    };
}
