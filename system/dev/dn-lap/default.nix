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
    domain = "net.dn";
    hyprland = {
      enable = true;
      monitors = [
        {
          desc = "LG Display 0x0665";
          output = "eDP-1";
          props = "preferred, 0x0, 1.25";
        }
      ];
    };
  };

  imports = [
    ../../modules/presets/basic.nix
    ./common
    ./games
    ./home
    ./office
    ./services
    ./sops
    ./utility
    ./virtualisation
  ];

  users.users."${username}".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMj/LeB3i/vca3YwGNpAjf922FgiY2svro48fUSQAjOv Shortcuts on :D"
  ];
}
