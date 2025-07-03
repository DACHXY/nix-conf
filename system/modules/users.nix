{
  settings,
  pkgs,
  lib,
  config,
  ...
}:

{
  users.users.${settings.personal.username} = {
    isNormalUser = true;
    shell = pkgs.bash; # Actually fish
    extraGroups = (
      [
        "wheel"
        "input"
        "networkmanager"
        "docker"
        "kvm"
      ]
      ++ (if config.programs.gamemode.enable then [ "gamemode" ] else [ ])
    );
  };
}
