{ hostname }:
{
  pkgs,
  ...
}:
let
  username = "skydrive";
in
{
  systemConf = {
    inherit hostname username;
    domain = "net.dn";
    hyprland.enable = true;
    face = pkgs.fetchurl {
      url = "https://files.net.dn/skydrive.jpg";
      hash = "sha256-aMjl6VL1Zy+r3ElfFyhFOlJKWn42JOnAFfBXF+GPB/Q=";
      curlOpts = "-k";
    };
  };

  imports = [
    ../../modules/presets/basic.nix
    ./common
    ./games
    ./services
    ./sops
    ./utility
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
  ];

  users.users."${username}".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBDk8GmC7b9+XSDxnIj5brYmNLPVO47G5enrL3Q+8fuh 好強上的捷徑"
  ];
}
