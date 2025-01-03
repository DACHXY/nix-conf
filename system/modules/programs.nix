{ pkgs, config, ... }:

let
  getIconScript = pkgs.writeShellScriptBin "get-icon" (
    builtins.readFile ../../home/config/scripts/getIcons.sh
  );
in
{
  programs = {
    gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };

    tmux = {
      enable = true;
      escapeTime = 0;

      plugins = with pkgs; [
        tmuxPlugins.vim-tmux-navigator
        tmuxPlugins.resurrect
        tmuxPlugins.continuum
        tmuxPlugins.catppuccin
      ];

      extraConfig = ''
        set -gq allow-passthrough on
        set -g status "on"
        set -g status-style fg=default,bg=default
        set -g status-position top
        set -g status-justify "left"

        set -g status-left "#[fg=#84977f,bg=default,bold] █ session: #S"
        set -g status-right "  #[fg=#828bb8,bg=default,bold]${config.networking.hostName}    "

        setw -g window-status-format "#[fg=#171616,bg=default]  #[fg=#495361,bg=default]#(${getIconScript}/get-icon #I) #W"
        setw -g window-status-current-format "#[fg=#7e93a9,bg=default]  #[fg=#7e93a9,bg=default,bold]#(${getIconScript}/get-icon #I) #W"


        set -g default-terminal "xterm-256color"
        set -ga terminal-overrides ",*256col*:Tc"
        set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
        set-environment -g COLORTERM "truecolor"
        set -g prefix C-b
        bind-key C-b send-prefix

        unbind %
        bind | split-window -h

        unbind '"'
        bind - split-window -v

        unbind r
        bind r source-file ~/.tmux.conf

        bind -r j resize-pane -D 5
        bind -r k resize-pane -U 5
        bind -r l resize-pane -R 5
        bind -r h resize-pane -L 5

        bind -r m resize-pane -Z

        set -g mouse on

        set-window-option -g mode-keys vi

        bind-key -T copy-mode-vi 'v' send -X begin-selection
        bind-key -T copy-mode-vi 'y' send -X copy-selection

        unbind -T copy-mode-vi MouseDragEnd1Pane

        set -g @resurrect-capture-pane-contents 'on'
        set -g @continuum-restore 'on'
        set -g @catppuccin-flavour 'macchiato'
      '';
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
