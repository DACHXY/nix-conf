{ ... }:
{
  imports = [
    (import ../../../../home/user/git.nix {
      username = "dachxy";
      email = "dachxy@dnywe.com";
    })
  ];
}
