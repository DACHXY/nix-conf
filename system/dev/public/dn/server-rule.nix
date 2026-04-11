{ ... }:
let
  securityModule = "${
    fetchGit {
      url = "ssh://git.dnywe.com/dachxy/nix-server-security.git";
      rev = "9a8e6ccdcc3c459b6ee872e7fd578b139fb0c223";
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
