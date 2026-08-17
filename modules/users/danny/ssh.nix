{ ... }:
{
  flake.modules.generic.danny = nixosArgs: {
    users.users.${nixosArgs.config.my.user.name} = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMj/LeB3i/vca3YwGNpAjf922FgiY2svro48fUSQAjOv Shortcuts on :D"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII17Qa46NpiXRZfWTgXvGN00wfaQuH1MeHPjvqy4Go4r danny@dn-notebook"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMT/rhCBp90SBW15dObrI1vl48uIdbjzwK+LQxtd/m8m danny@dn-workstation"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9Z/yjOAnEOk4oRRruE0s+15B1W6bhu7TK81jAMgkVA danny@dn-cscc"
      ];
    };
  };
}
