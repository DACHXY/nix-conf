{ settings, pkgs, ... }:

{
  users.users.${settings.personal.username} = {
    isNormalUser = true;
    shell = pkgs.bash; # Actually fish
    extraGroups = [
      "wheel"
      "input"
      "networkmanager"
      "docker"
      "kvm"
    ];
  };
}
