{ ... }:
{
  flake.modules.generic.danny = nixosArgs: {
    users.users.${nixosArgs.config.my.user.name} = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
        # iPhone (Shortcuts app)
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMj/LeB3i/vca3YwGNpAjf922FgiY2svro48fUSQAjOv Shortcuts on :D"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII17Qa46NpiXRZfWTgXvGN00wfaQuH1MeHPjvqy4Go4r danny@dn-notebook"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMT/rhCBp90SBW15dObrI1vl48uIdbjzwK+LQxtd/m8m danny@dn-workstation"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9Z/yjOAnEOk4oRRruE0s+15B1W6bhu7TK81jAMgkVA danny@dn-cscc"
        # FIDO2 keys created with `-O verify-required`: every signature needs the
        # device PIN and a touch. Also trusted by pam_rssh (remote sudo) via
        # /etc/ssh/fido2_authorized_keys in yubikey.nix.
        # RP2350 #1 (primary)
        "verify-required sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBEU4+o6X7HT/i1hJuB8kOZ2BBxEuM0RTZrrDo8gsYZUkVFleYl1dvR09+nQLqRLbcmPfe9ebGxhfjEJCkxkQgg4AAAAEc3NoOg== danny@fido-rp2350a"
        # RP2040 (backup)
        "verify-required sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBJ3AkhPMtjvOoDCV0+of0MNYPyzw5bshx3WVrkB5VEG0+WDy5BCAn13nHAZqbj4c0CYtKPRySACbhtD7ydMw2OAAAAAEc3NoOg== danny@fido-rp2040"
        # RP2350 #2 (backup)
        "verify-required sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBJ2hYWaqYbYwzDqmNXhWXA/iabMUXiRNRvZwsIU9YcB2YVw7L2BfyhZfJux7PWFPYyrM5HCPzHGUAjevOIsVpH0AAAAEc3NoOg== danny@fido-rp2350b"
      ];
    };
  };
}
