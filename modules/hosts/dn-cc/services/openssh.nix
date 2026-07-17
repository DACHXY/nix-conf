{
  configurations.nixos.dn-cc.module =
    {
      ...
    }:
    {
      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMT/rhCBp90SBW15dObrI1vl48uIdbjzwK+LQxtd/m8m danny@dn-workstation"
      ];
    };
}
