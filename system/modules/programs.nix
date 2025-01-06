{ pkgs, ... }:

{
  programs = {
    gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };

    dconf.enable = true;
    zsh.enable = true;
    mtr.enable = true;
    fish.enable = true;

    # Set fish as default shell but not login shell
    bash = {
      interactiveShellInit = ''
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };
  };

}
