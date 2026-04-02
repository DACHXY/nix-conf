{ ... }:
let
  extra-modules = "${
    fetchGit {
      url = "ssh://git.dnywe.com/dachxy/extra-modules.git";
      rev = "2f5755df4183ec3b174126d2a3945c350cb2ac61";
      ref = "main";
    }
  }/modules/default.nix";
in
{
  imports = [
    # ./osx-kvm.nix
    extra-modules
    ./noise-cancel.nix
    ./acme.nix
  ];
}
