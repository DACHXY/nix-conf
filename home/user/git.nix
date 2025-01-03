{ git-config, ... }:
let
  userName = git-config.username;
  email = git-config.email;
in
{
  programs.git = {
    enable = true;
    userName = userName;
    userEmail = email;
    extraConfig = {
      safe.directory = [ "/etc/nixos" ];
    };
  };
}
