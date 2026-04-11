{ ... }:
let
  extra-modules = "${
    fetchGit {
      url = "ssh://git.dnywe.com/dachxy/extra-modules.git";
      rev = "573ac5cd007e00d8ae3a56b718625273759e19ad";
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
