{ settings, ... }:
{
  programs.git = {
    enable = true;
    userName = settings.personal.git.username;
    userEmail = settings.personal.git.email;
    extraConfig = {
      safe.directory = [ "/etc/nixos" ];
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
