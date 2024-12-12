{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ./modules ];

  system.stateVersion = "24.11";
}

