{ hostname }:
{
  ...
}:
let
  username = "danny";
in
{
  systemConf = {
    inherit hostname username;
    niri.enable = true;
  };

  imports = [
    ../../modules/presets/basic.nix
    ../public/dn
    ../public/dn/ntfy.nix
    ./common
    ./games
    ./home
    ./office
    ./services
    ./sops
    ./utility
    ./virtualisation
    ./network
  ];

  users.users."${username}".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMj/LeB3i/vca3YwGNpAjf922FgiY2svro48fUSQAjOv Shortcuts on :D"
  ];
}
