{ ... }:
let
  securityModule = "${
    fetchGit {
      url = "ssh://git.dnywe.com/dachxy/nix-server-security.git";
      rev = "14647680587e1421a1f51354f26d12704a32009d";
      ref = "main";
    }
  }/default.nix";
in
{
  imports = [
    ../../../../options/server
    securityModule
  ];
}
