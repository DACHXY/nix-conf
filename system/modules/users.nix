{
  pkgs,
  config,
  ...
}:
let
  inherit (config.systemConf) username;
in
{
  users.users.${username} = {
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
