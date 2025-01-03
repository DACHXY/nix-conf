{ username, pkgs, ... }:

{
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.bash; # Actually fish
    extraGroups = [
      "wheel"
      "input"
      "networkmanager"
      "docker"
      "libvirtd"
      "kvm"
    ];
  };
}
