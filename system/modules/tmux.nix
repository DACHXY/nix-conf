{ pkgs, config, ... }:

let
  getIconScript = pkgs.writeShellScriptBin "get-icon" (
    builtins.readFile ../../home/config/scripts/getIcons.sh
  );
  prefixKey = "C-Space";
  tmuxConfigPath = "/etc/tmux.conf";
in
{
  environment.variables = {
    TMUXINATOR_CONFIG = "/etc/tmuxinator";
  };
  environment.etc = {
    "tmuxinator/tmux.yaml" = {
      source = ../../home/config/tmux.yaml;
      mode = "0444";
    };
  };

  environment.systemPackages = with pkgs; [
    tmuxinator
  ];

  programs = {
    tmux = {
      enable = true;
      escapeTime = 0;

      plugins = with pkgs; [
        tmuxPlugins.vim-tmux-navigator
        tmuxPlugins.resurrect
        tmuxPlugins.continuum
        tmuxPlugins.catppuccin
        tmuxPlugins.yank
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

        unbind C-b
        set -g prefix ${prefixKey}
        bind-key ${prefixKey} send-prefix

        # Set Window start at 1
        set -g base-index 1 
        set -g pane-base-index 1
        set-window-option -g pane-base-index 1
        set-option -g renumber-windows on

        # Switch Windows (Shift + Alt + h/l)
        bind -n M-H previous-window
        bind -n M-L next-window

        unbind %
        bind | split-window -h -c "#{pane_current_path}"

        unbind '"'
        bind - split-window -v -c "#{pane_current_path}"

        unbind r
        bind r source-file ${tmuxConfigPath}

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

        unbind f 
        bind-key -r f run-shell "tmux neww tmux-sessionizer"

        set -g @resurrect-capture-pane-contents 'on'
        set -g @continuum-restore 'on'
        set -g @catppuccin-flavour 'macchiato'
      '';
    };
  };
}
