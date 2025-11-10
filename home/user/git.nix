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

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
    gitCredentialHelper = {
      enable = true;
    };
  };
}
