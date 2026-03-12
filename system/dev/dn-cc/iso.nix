{ pkgs, modulesPath, ... }:
let
  inherit (builtins) getEnv;
  ip = getEnv "CC_IP";
  prefix = 25;
  gateway = getEnv "CC_GATEWAY";
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    (modulesPath + "/installer/cd-dvd/channel.nix")
    (import ./network.nix { inherit ip prefix gateway; })
  ];

  environment.systemPackages = [
    pkgs.neovim
    pkgs.jq
    pkgs.fish
  ];
}
