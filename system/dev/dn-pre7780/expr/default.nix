{ ... }:
let
  extra-modules = "${
    fetchGit {
      url = "https://git.dnywe.com/dachxy/extra-modules";
      rev = "cce58d705bee67e0634d4353b5eb40bd4a99ca42";
      ref = "main";
    }
  }/modules//default.nix";
in
{
  imports = [
    # ./osx-kvm.nix
    extra-modules
    ./noise-cancel.nix
    ./acme.nix
  ];
}
