{ config, pkgs, pkgs-unstable, lib, inputs, ... }:

{
  imports = [ ./user ];

  home.username = "danny";
  home.homeDirectory = "/home/danny";
  home.stateVersion = "24.11";
}

