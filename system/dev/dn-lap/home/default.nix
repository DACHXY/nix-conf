{
  pkgs,
  config,
  ...
}:
let
  inherit (config.systemConf) username;
in
{
  home-manager.users."${username}" = {
    home.packages = with pkgs; [
      mattermost-desktop
    ];

    imports = [
      ../../../../home/presets/basic.nix
      ../../../../home/user/zellij.nix
      ./noctalia.nix
    ];
  };
}
