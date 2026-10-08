{
  flake.modules.homeManager.base =
    { pkgs, lib, ... }:
    let
      # herdr has no declarative plugin registry: plugins are registered with the
      # imperative `herdr plugin link`. So nix builds the plugin and the module
      # links it at activation (see below).
      herdrPaneNameSrc = pkgs.fetchFromGitHub {
        owner = "go-min";
        repo = "herdr-pane-name";
        rev = "02ab7a62026008879e46fa972af49116ea2b66b9";
        hash = "sha256-54w3WiyXiNGCydrC2NjwEOTahjPjVZZYYfhkG/4PEhs=";
      };

      # The manifest runs `./target/release/herdr-pane-name`, so the binary has
      # to sit at that relative path inside the plugin root.
      herdrPaneName = pkgs.rustPlatform.buildRustPackage {
        pname = "herdr-pane-name";
        version = "0.1.1";
        src = herdrPaneNameSrc;
        cargoHash = "sha256-r/NhEg7+etz8UsDnwIgtsyV487p+3dcIjWo4091PgZo=";
        doCheck = false;
      };
      herdrPaneNamePlugin = pkgs.runCommand "herdr-pane-name-plugin" { } ''
        mkdir -p $out/target/release
        cp ${herdrPaneNameSrc}/herdr-plugin.toml $out/herdr-plugin.toml
        cp ${herdrPaneNameSrc}/config.example.toml $out/config.example.toml
        ln -s ${herdrPaneName}/bin/herdr-pane-name $out/target/release/herdr-pane-name
      '';

      herdrSessionizer = pkgs.writeShellApplication {
        name = "herdr-sessionizer";
        runtimeInputs = with pkgs; [
          fzf
          git
          herdr
          jq
        ];
        text = ''
          extra_dir=${if pkgs.stdenv.hostPlatform.isDarwin then "$HOME/nix" else "/etc/nixos"}

          if [[ $# -eq 1 ]]; then
            selected=$1
          else
            # fzf exits 1 when the query matches nothing — accepting that query
            # is exactly how a clone URL gets entered, so it must not trip errexit.
            fzf_out=$( (
              find "$HOME/projects" "$HOME/notes" -mindepth 1 -maxdepth 1 -type d 2> /dev/null
              printf '%s\n' "$extra_dir"
            ) | fzf --print-query --header='select a project, or type a git URL to clone' ) || true
            # fzf prints the typed query first, then the chosen match if any.
            # An unmatched query is how a clone URL gets entered.
            selected=$(printf '%s\n' "$fzf_out" | tail -n +2)
            [[ -z $selected ]] && selected=$(printf '%s\n' "$fzf_out" | head -n 1)
          fi

          # A git-cloneable address clones into ~/projects first, then flows
          # through the same workspace-name/path logic below.
          case "$selected" in
            *://* | git@*:* | *.git)
              dest="$HOME/projects/$(basename "$selected" .git | tr . _)"
              if [[ ! -d $dest ]]; then
                git clone "$selected" "$dest" || exit 1
              fi
              selected=$dest
              ;;
          esac

          if [[ -z $selected ]]; then
            exit 0
          fi

          selected_name=$(basename "$selected" | tr . _)

          # Nothing running to talk to: start herdr there instead. terminal.new_cwd
          # is "follow", so the first workspace inherits this directory.
          if ! herdr workspace list > /dev/null 2>&1; then
            cd "$selected"
            exec herdr
          fi

          # Reuse the workspace with this label if it exists, else create it.
          # The label may carry a `N:` jump-key prefix added by herdr-pane-name,
          # so compare the name with that prefix stripped.
          existing=$(herdr workspace list | jq -r --arg n "$selected_name" \
            '.result.workspaces[] | select((.label | sub("^[0-9]+:"; "")) == $n) | .workspace_id' | head -n 1)

          if [[ -n $existing ]]; then
            herdr workspace focus "$existing"
          else
            herdr workspace create --cwd "$selected" --label "$selected_name" --focus
          fi

          # Outside herdr there is no attached client for the focus to act on,
          # so attach one — the herdr analogue of tmux's `new-session -A`.
          # Inside a herdr pane (the prefix+f popup) focusing is enough.
          if [[ -z ''${HERDR_ENV:-} ]]; then
            exec herdr
          fi
        '';
      };

      # Same idea as herdr-sessionizer, but for jumping straight to a running
      # agent: fzf over `herdr agent list`, then focus by pane id.
      herdrAgentizer = pkgs.writeShellApplication {
        name = "herdr-agentizer";
        runtimeInputs = with pkgs; [
          fzf
          herdr
          jq
        ];
        text = ''
          rows=$(herdr agent list \
            | jq -r '.result.agents[]
                | [ .pane_id,
                    ( .agent_status + "  " + .agent + "  "
                      + .foreground_cwd + "  " + .terminal_title_stripped ) ]
                | @tsv')

          [[ -z $rows ]] && exit 0

          # The pane id is field 1 and stays out of the display: --with-nth only
          # hides it from fzf, the selected line is still the whole row.
          selected=$(printf '%s\n' "$rows" \
            | fzf --delimiter='\t' --with-nth=2 --prompt='agent> ' \
                --header='select an agent (status, agent, dir, title)') || true

          [[ -z $selected ]] && exit 0

          herdr agent focus "$(printf '%s' "$selected" | cut -f1)"

          # Outside herdr nothing is attached to receive the focus, so attach a
          # client — the same fallback herdr-sessionizer uses.
          if [[ -z ''${HERDR_ENV:-} ]]; then
            exec herdr
          fi
        '';
      };

      # Pull a pane from any other workspace into the calling tab as a split.
      # `pane move` takes the destination tab explicitly and `--target-pane`
      # anchors the new split next to the calling pane, so no empty panel has to
      # be opened first. If the source tab or workspace is left empty it closes.
      herdrPaneizer = pkgs.writeShellApplication {
        name = "herdr-paneizer";
        runtimeInputs = with pkgs; [ fzf herdr jq ];
        text = ''
          # A popup deliberately does not get HERDR_PANE_ID — HERDR_ACTIVE_PANE_ID
          # is the tiled pane it opened over. Derive the tab from that pane, so the
          # script behaves the same from a popup and from an ordinary pane.
          here=''${HERDR_ACTIVE_PANE_ID:-''${HERDR_PANE_ID:-}}
          if [[ -z $here ]]; then
            echo "herdr-paneizer must run inside a herdr pane" >&2
            exit 1
          fi
          tab=$(herdr pane get "$here" | jq -r '.result.pane.tab_id')

          # The pane id stays field 1 and out of the display; --with-nth only
          # hides it from fzf, so cut -f1 recovers it. Workspace labels
          # ("1:nix-conf") need a second lookup — the pane list carries only ids.
          rows=$(jq -rn \
            --slurpfile ws <(herdr workspace list) \
            --slurpfile pn <(herdr pane list) \
            --arg tab "$tab" '
              ($ws[0].result.workspaces
                | map({ key: .workspace_id, value: (.label // .workspace_id) })
                | from_entries) as $label
              | $pn[0].result.panes[]
              | select(.tab_id != $tab)
              | [ .pane_id,
                  ( ($label[.workspace_id] // .workspace_id) + "  " + .cwd
                    + "  " + (.terminal_title_stripped // "") ) ]
              | @tsv')
          [[ -z $rows ]] && exit 0

          selected=$(printf '%s\n' "$rows" \
            | fzf --delimiter='\t' --with-nth=2 --prompt='pane> ' \
                --header='pull a pane into this tab (workspace, dir, title)') || true
          [[ -z $selected ]] && exit 0

          # Hyprland-dwindle spawn: split the target along the axis
          # PERPENDICULAR to the region it already sits in, so the layout nests
          # (left | right -> left | right-top/right-bottom) instead of growing
          # one more full-height column. The ancestor region is the smallest
          # split rect that contains the pane; a one-pane tab has none, so it
          # splits right.
          split_dir=$(herdr pane layout --pane "$here" | jq -r --arg p "$here" '
            (.result.layout.panes[] | select(.pane_id == $p) | .rect) as $me
            | [ .result.layout.splits[]
                | select(.rect.x <= $me.x and .rect.y <= $me.y
                    and .rect.x + .rect.width  >= $me.x + $me.width
                    and .rect.y + .rect.height >= $me.y + $me.height) ]
            | sort_by(.rect.width * .rect.height)
            | if length == 0 then "right"
              elif .[0].direction == "right" then "down"
              else "right" end')

          herdr pane move "$(printf '%s' "$selected" | cut -f1)" \
            --tab "$tab" --split "$split_dir" --target-pane "$here" --no-focus
        '';
      };

      # Same role as tmux.nix's `ta`, but for herdr.
      ha = pkgs.writeShellScriptBin "ha" ''
        exec herdr-sessionizer "$@"
      '';

      # `hr <ssh-target>` attaches to a remote herdr server. The flag has to
      # follow the target, and `server` is the only mode where a custom
      # [[keys.command]] (prefix+f) exists at all: herdr strips command bindings
      # from the client's local keybinding profile on purpose.
      hr = pkgs.writeShellScriptBin "hr" ''
        exec herdr --remote "$@" --remote-keybindings server
      '';
    in
    {
      home.packages = [
        herdrSessionizer
        herdrAgentizer
        herdrPaneizer
        ha
        hr
        herdrPaneName
      ];

      # Updates pane/tab names right after a command starts and finishes; without
      # it names only refresh on herdr lifecycle/focus events.
      xdg.configFile."fish/conf.d/herdr-pane-name.fish".source = herdrPaneNameSrc + "/hooks/fish.fish";

      home.activation.herdrPaneName = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${lib.getExe pkgs.herdr} plugin list \
          | grep -q 'herdr.pane-name.*${herdrPaneNamePlugin}' \
          || ${lib.getExe pkgs.herdr} plugin link ${herdrPaneNamePlugin} > /dev/null
      '';

      programs.herdr = {
        enable = true;
        settings = {
          onboarding = false;

          # tmux used the catppuccin (macchiato) plugin.
          theme.name = "catppuccin";

          terminal.new_cwd = "follow";
          ui.mouse_capture = true; # tmux: `set -g mouse on`

          keys = {
            prefix = "ctrl+space"; # tmux: C-Space

            # The Cmd+Shift chord is the native macOS one (alt+shift is awkward
            # there). It is bound on every host so that a darwin client
            # attaching with `--remote-keybindings server` still gets it from
            # this config; no linux keyboard has a cmd key.
            previous_tab = [
              "alt+shift+h"
              "shift+cmd+h"
            ];
            next_tab = [
              "alt+shift+l"
              "shift+cmd+l"
            ];

            # Move the focused tab toward the front/back of the sidebar. (`swap_pane_*`
            # is the pane-level equivalent, but every tab here holds a single
            # full-width pane, so swapping a pane can never find a neighbour.)
            move_tab_previous = "ctrl+shift+h";
            move_tab_next = "ctrl+shift+l";

            # Navigate mode (`prefix+g`). Its movement keys are mode-local and
            # accept plain letters; the defaults are j/k = pane down/up and
            # up/down = workspace selection. This swaps them, so j/k move the
            # workspace selection vim-style and the arrows move panes. h/l are
            # untouched — left/right are permanent aliases for pane movement.
            # `enter` switches to the selected workspace.
            navigate_workspace_up = "k";
            navigate_workspace_down = "j";
            navigate_pane_up = "up";
            navigate_pane_down = "down";

            # Pane focus. A list replaces herdr's default instead of adding to
            # it, so prefix+h/j/k/l is repeated to keep it working.
            focus_pane_left = [ "ctrl+alt+h" "prefix+h" ];
            focus_pane_down = [ "ctrl+alt+j" "prefix+j" ];
            focus_pane_up = [ "ctrl+alt+k" "prefix+k" ];
            focus_pane_right = [ "ctrl+alt+l" "prefix+l" ];

            # Directional pane move: pushes the focused pane past its
            # neighbour. herdr 0.9.3 defines the swap_pane_* actions but ships
            # no default binding for them.
            swap_pane_left = "ctrl+alt+shift+h";
            swap_pane_down = "ctrl+alt+shift+j";
            swap_pane_up = "ctrl+alt+shift+k";
            swap_pane_right = "ctrl+alt+shift+l";

            toggle_sidebar = [
              "prefix+b"
              "ctrl+shift+e"
              "ctrl+cmd+e"
            ];

            zoom = "prefix+m"; # tmux: prefix+m

            command = [
              {
                key = "prefix+f";
                type = "popup";
                command = "herdr-sessionizer";
                width = "80%";
                height = "80%";
              }
              {
                key = "prefix+a";
                type = "popup";
                command = "herdr-agentizer";
                width = "80%";
                height = "80%";
              }
              {
                key = "prefix+p";
                type = "popup";
                command = "herdr-paneizer";
                width = "80%";
                height = "80%";
              }
            ];
          };
        };
      };
    };
}
