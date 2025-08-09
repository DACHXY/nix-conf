{
  username,
  email,
}:
{ ... }:
{
  programs.git = {
    enable = true;
    userName = username;
    userEmail = email;
    extraConfig = {
      safe.directory = [ "/etc/nixos" ];
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
