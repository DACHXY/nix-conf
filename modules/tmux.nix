{
  flake.modules.generic.base =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      inherit (lib) concatStringsSep optionalAttrs;

      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

      findDirs = [
        "~/projects"
        "~/notes"
      ];
      extraDirs = if isDarwin then [ "~/nix" ] else [ "/etc/nixos" ];

      tmuxSessionizer = pkgs.writeShellScriptBin "tmux-sessionizer" ''
        EXTRA_DIRS=${concatStringsSep "\n" extraDirs}

        if [[ $# -eq 1 ]]; then
            selected=$1
        else
            selected=$( ( \
            find ${concatStringsSep " " findDirs} -mindepth 1 -maxdepth 1 -type d; \
            printf "%s\n" $EXTRA_DIRS \
            ) | fzf )
        fi

        if [[ -z $selected ]]; then
            exit 0
        fi

        selected_name=$(basename "$selected" | tr . _)
        # Outside tmux there is no client for switch-client to act on, and
        # `pgrep tmux` matches the server even with nothing attached, so it
        # cannot tell "no tmux" from "tmux running, I'm just not in it".
        # -A does the attach-vs-create decision instead.
        if [[ -z $TMUX ]]; then
            tmux new-session -A -s $selected_name -c $selected
            exit 0
        fi

        if ! tmux has-session -t=$selected_name 2> /dev/null; then
            tmux new-session -ds $selected_name -c $selected
        fi

        tmux switch-client -t $selected_name
      '';

      ta = pkgs.writeShellScriptBin "ta" ''
        exec tmux-sessionizer "$@"
      '';

      ryank = pkgs.writeShellScriptBin "ryank" ''
        # copy via OSC 52
        buf=$( cat "$@" )
        len=$( printf %s "$buf" | wc -c ) max=74994
        test $len -gt $max && echo "$0: input is $(( len - max )) bytes too long" >&2
        printf "\033]52;c;$( printf %s "$buf" | head -c $max | base64 | tr -d '\r\n' )\a"
      '';

      getIconScript = pkgs.writeShellScript "get-icon" ''
        get_icons() {
          local session_name="$1"
          local result=""

          local panes=($(tmux list-panes -t "$session_name" -F '#{pane_current_command}'))

          for i in "''\${panes[@]}"; do
            case "$i" in
            nvim) result+=" " ;;
            zsh | *) result+=" " ;;
            esac
          done

          echo "$result"
        }

        if (($# != 1)); then
          echo "Usage: $0 <session-name>"
          exit 1
        fi

        get_icons "$1"
      '';
      prefixKey = "C-Space";
      tmuxConfigPath = "/etc/tmux.conf";
    in
    {
      environment.systemPackages = [
        ta
        ryank
        tmuxSessionizer
      ];

      programs.tmux = {
        enable = true;
        extraConfig = ''
          set -g allow-passthrough on
          set -s set-clipboard on
          set-option -s set-clipboard on
          # extended-keys is deliberately OFF. When it is on (together with an
          # `xterm-ghostty:extkeys` terminal-feature line) tmux stops folding the
          # legacy ESC-prefixed meta keys. Ghostty ignores tmux's modifyOtherKeys
          # enable and still sends `ESC H` for Shift+Alt+h, which tmux then passes
          # through as a literal Escape + 'h' instead of M-H, so `bind -n M-H`
          # never fires. Off keeps M-H/M-L working; the csi-u kitty sequences
          # inside tmux were never actually delivered by ghostty anyway.
          set -g extended-keys off

          set -g status "on"
          set -g status-style fg=default,bg=default
          set -g status-position top
          set -g status-justify "left"

          set -g status-left "#[fg=#84977f,bg=default,bold] █ session: #S"
          set -g status-right "  #[fg=#828bb8,bg=default,bold]${config.networking.hostName}    "

          setw -g window-status-format "#[fg=#171616,bg=default]  #[fg=#495361,bg=default]#(${getIconScript} #I) #W"
          setw -g window-status-current-format "#[fg=#7e93a9,bg=default]  #[fg=#7e93a9,bg=default,bold]#(${getIconScript} #I) #W"

          set -g default-terminal "tmux-256color"
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

          # Switch Windows (Shift + Alt + h/l). Ghostty sends the legacy
          # ESC-prefixed meta form (`ESC H`), which tmux folds to M-H.
          bind -n M-H previous-window
          bind -n M-L next-window

          # Move Windows
          bind-key -n C-S-h swap-window -t -1\; select-window -t -1
          bind-key -n C-S-l swap-window -t +1\; select-window -t +1
          bind -n Ó previous-window # For darwin (Shift + Option + H)
          bind -n Ò next-window     # For darwin (Shift + Option + L)

          unbind %
          bind | split-window -h -c "#{pane_current_path}"

          unbind '"'
          bind - split-window -v -c "#{pane_current_path}"

          # Reload config
          unbind R
          bind R source-file ${tmuxConfigPath}

          # rename
          unbind r
          bind r command-prompt -I "#W" "rename-window '%%'"

          # Move Focus
          bind -r j select-pane -D
          bind -r k select-pane -U
          bind -r l select-pane -R
          bind -r h select-pane -L

          # Resize Panel
          bind -r Left  resize-pane -L 5
          bind -r Down  resize-pane -D 5
          bind -r Up    resize-pane -U 5
          bind -r Right resize-pane -R 5

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
      }
      # nix-darwin's tmux module has no `plugins`/`escapeTime`. Its enableMouse
      # also drops the xterm smcup/rmcup override and enableVim adds
      # non-repeatable pane binds, so neither is a duplicate of extraConfig.
      // optionalAttrs isDarwin {
        enableMouse = true;
        enableVim = true;
      }
      // optionalAttrs (!isDarwin) {
        escapeTime = 0;

        plugins = with pkgs; [
          tmuxPlugins.vim-tmux-navigator
          tmuxPlugins.resurrect
          tmuxPlugins.continuum
          tmuxPlugins.catppuccin
          tmuxPlugins.yank
        ];
      };
    };
}
