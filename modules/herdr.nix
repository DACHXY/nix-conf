{
  # Local patches, re-check both on herdr upgrades:
  # - herdr-popup-scoped-focus: upstream broadcasts focus requests to every
  #   client, so a popup moved every workspace. The patch scopes the request to
  #   the popup's opener, else the foreground client.
  # - herdr-pi-bolt-session-restore: Pi-Bolt reports source `pi-bolt`/label
  #   `pi-bolt`, which herdr does not whitelist, and herdr parks the first
  #   session report, so restored panes came back as plain shells. The patch
  #   aliases source and label and anchors the first report.
  nixpkgs.overlays = [
    (final: prev: {
      herdr = prev.herdr.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../patches/herdr-popup-scoped-focus.patch
          ../patches/herdr-pi-bolt-session-restore.patch
        ];
      });
    })
  ];

  flake.modules.homeManager.base =
    { pkgs, lib, osConfig, ... }:
    let
      # herdr-core (`hc`) is the runtime the Herdr mobile app talks to over SSH;
      # the TUI's server is separate. Desktops only.
      herdrCoreHosts = [
        "dn-cscc"
        "dn-workstation"
      ];
      # herdr has no declarative plugin registry (plugins come from the
      # imperative `herdr plugin link`), so nix builds the plugin and activation
      # links it.
      herdrPaneNameSrc = pkgs.fetchFromGitHub {
        owner = "go-min";
        repo = "herdr-pane-name";
        rev = "02ab7a62026008879e46fa972af49116ea2b66b9";
        hash = "sha256-54w3WiyXiNGCydrC2NjwEOTahjPjVZZYYfhkG/4PEhs=";
      };

      # The manifest runs ./target/release/herdr-pane-name, so the symlink has
      # to sit at that relative path.
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

      # Upstream's fish hook launches its background jobs without `disown`, so an
      # interactive `exit` complains about active jobs. Disown each job, ignoring
      # the error when it already finished.
      herdrPaneNameFishHook = pkgs.runCommandLocal "herdr-pane-name-fish-hook" { } ''
        install -Dm644 ${herdrPaneNameSrc}/hooks/fish.fish $out/fish.fish
        substituteInPlace $out/fish.fish \
          --replace-fail '>/dev/null 2>&1 &' '>/dev/null 2>&1 &; disown 2>/dev/null' \
          --replace-fail '    end &' '    end &; disown 2>/dev/null'
      '';

      herdrSessionizer = pkgs.writeShellApplication {
        name = "herdr-sessionizer";
        runtimeInputs = with pkgs; [
          coreutils
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
            # fzf exits 1 on no match, and an unmatched query is exactly how a
            # clone URL gets entered, so it must not trip errexit.
            fzf_out=$( (
              find "$HOME/projects" "$HOME/notes" -mindepth 1 -maxdepth 1 -type d 2> /dev/null
              printf '%s\n' "$extra_dir"
            ) | fzf --print-query --header='select a project, or type a git URL to clone [optional folder name]' ) || true
            # Query first, chosen match second; no match means the query is the
            # clone URL.
            selected=$(printf '%s\n' "$fzf_out" | tail -n +2)
            [[ -z $selected ]] && selected=$(printf '%s\n' "$fzf_out" | head -n 1)
          fi

          # A clone-able address clones into ~/projects and falls through to the
          # switch logic; an optional second word names the folder, otherwise the
          # URL's basename is used (` .git` and dots stripped from that default only).
          read -r clone_url clone_name <<< "$selected" || true
          case "$clone_url" in
            *://* | git@*:* | *.git)
              if [[ -n $clone_name ]]; then
                dest="$HOME/projects/$clone_name"
              else
                dest="$HOME/projects/$(basename "$clone_url" .git | tr . _)"
              fi
              if [[ ! -d $dest ]]; then
                git clone "$clone_url" "$dest" || exit 1
              fi
              selected=$dest
              ;;
          esac

          if [[ -z $selected ]]; then
            exit 0
          fi

          # A name matching no directory is a new project under ~/projects.
          if [[ ! -d $selected ]]; then
            selected="$HOME/projects/$(basename "$selected" | tr . _)"
            mkdir -p "$selected"
          fi

          selected_name=$(basename "$selected" | tr . _)

          # No server to talk to: start herdr here (terminal.new_cwd = "follow").
          if ! herdr workspace list > /dev/null 2>&1; then
            cd "$selected"
            exec herdr
          fi

          # Reuse the workspace with this label, else create it. herdr-pane-name
          # prefixes labels with `N:`, so compare the name without it.
          existing=$(herdr workspace list | jq -r --arg n "$selected_name" \
            '.result.workspaces[] | select((.label | sub("^[0-9]+:"; "")) == $n) | .workspace_id' | head -n 1)

          if [[ -n $existing ]]; then
            herdr workspace focus "$existing"
          else
            herdr workspace create --cwd "$selected" --label "$selected_name" --focus
          fi

          # Nothing outside a herdr pane is attached to receive the focus, so
          # attach a client (tmux's `new-session -A` analogous); inside the popup
          # focusing is enough.
          if [[ -z ''${HERDR_ENV:-} ]]; then
            exec herdr
          fi
        '';
      };

      # Like herdr-sessionizer, but jumps to a running agent: fzf over `herdr
      # agent list`, then focus by pane id.
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

          # The pane id is field 1, hidden from display only (--with-nth does not
          # alter the selected line).
          selected=$(printf '%s\n' "$rows" \
            | fzf --delimiter='\t' --with-nth=2 --prompt='agent> ' \
                --header='select an agent (status, agent, dir, title)') || true

          [[ -z $selected ]] && exit 0

          herdr agent focus "$(printf '%s' "$selected" | cut -f1)"

          # Nothing outside herdr is attached to receive the focus.
          if [[ -z ''${HERDR_ENV:-} ]]; then
            exec herdr
          fi
        '';
      };

      # Pull a pane from another workspace into this tab as a split; an emptied
      # source tab or workspace closes.
      herdrPaneizer = pkgs.writeShellApplication {
        name = "herdr-paneizer";
        runtimeInputs = with pkgs; [ fzf herdr jq ];
        text = ''
          # A popup gets no HERDR_PANE_ID; HERDR_ACTIVE_PANE_ID is the tiled pane
          # it opened over, so both paths behave the same.
          here=''${HERDR_ACTIVE_PANE_ID:-''${HERDR_PANE_ID:-}}
          if [[ -z $here ]]; then
            echo "herdr-paneizer must run inside a herdr pane" >&2
            exit 1
          fi
          tab=$(herdr pane get "$here" | jq -r '.result.pane.tab_id')

          # Pane id stays field 1 and out of the display; workspace labels
          # ("1:nix-conf") need a second lookup since the pane list only has ids.
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

          # Hyprland-dwindle spawn: split along the axis perpendicular to the
          # region the pane already sits in, so the layout nests instead of
          # growing another full-height column. A one-pane tab splits right.
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

      # nvim-style jumplist for workspaces: `back`/`forward` walk the visit order.
      # herdr's own previous_workspace only cycles sidebar order, so the history
      # lives here: `daemon` subscribes to workspace.focused over the API socket
      # and keeps entries/index in a state file, and jumps pre-write `pending` so
      # the focus event they cause is not recorded as a new visit.
      herdrWorkspaceHistoryPy = pkgs.writeText "herdr-workspace-history.py" ''
        import contextlib
        import fcntl
        import json
        import os
        import socket
        import sys
        import time
        from pathlib import Path

        SOCKET_PATH = os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser(
            "~/.config/herdr/herdr.sock"
        )
        STATE_HOME = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
        STATE_DIR = Path(
            os.environ.get("HERDR_WORKSPACE_HISTORY_DIR")
            or Path(STATE_HOME) / "herdr-workspace-history"
        )
        STATE_FILE = STATE_DIR / "state.json"
        LOCK_FILE = STATE_DIR / "lock"
        MAX_ENTRIES = 100
        PENDING_TTL = 10.0


        def call(method, params, timeout=10.0):
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                sock.settimeout(timeout)
                sock.connect(SOCKET_PATH)
                sock.sendall(
                    (json.dumps({"id": "1", "method": method, "params": params}) + "\n").encode()
                )
                buf = b""
                while b"\n" not in buf:
                    chunk = sock.recv(65536)
                    if not chunk:
                        break
                    buf += chunk
            line = buf.split(b"\n", 1)[0]
            if not line:
                raise RuntimeError(method + ": empty reply")
            message = json.loads(line)
            if "error" in message:
                raise RuntimeError(method + ": " + json.dumps(message["error"]))
            return message["result"]


        def list_workspaces():
            return call("workspace.list", {}).get("workspaces", [])


        def focused_id(workspaces):
            for workspace in workspaces:
                if workspace.get("focused"):
                    return workspace["workspace_id"]
            return None


        def load_state():
            try:
                state = json.loads(STATE_FILE.read_text())
                if isinstance(state, dict) and isinstance(state.get("entries"), list):
                    state.setdefault("index", -1)
                    state.setdefault("pending", {})
                    return state
            except (OSError, ValueError):
                pass
            return {"entries": [], "index": -1, "pending": {}}


        def save_state(state):
            STATE_DIR.mkdir(parents=True, exist_ok=True)
            tmp = STATE_FILE.with_name(STATE_FILE.name + ".tmp")
            tmp.write_text(json.dumps(state))
            tmp.replace(STATE_FILE)


        @contextlib.contextmanager
        def state_lock():
            STATE_DIR.mkdir(parents=True, exist_ok=True)
            with open(LOCK_FILE, "w") as handle:
                fcntl.flock(handle, fcntl.LOCK_EX)
                try:
                    yield
                finally:
                    fcntl.flock(handle, fcntl.LOCK_UN)


        def prune_pending(pending, now):
            return {ws: stamp for ws, stamp in pending.items() if now - stamp <= PENDING_TTL}


        def record_visit(workspace_id):
            now = time.time()
            with state_lock():
                state = load_state()
                pending = prune_pending(state.get("pending") or {}, now)
                state["pending"] = pending
                if workspace_id in pending:
                    # Focus we asked for ourselves: the index already points here.
                    del pending[workspace_id]
                    save_state(state)
                    return
                entries = state["entries"]
                index = state["index"]
                if entries and 0 <= index < len(entries) and entries[index] == workspace_id:
                    save_state(state)
                    return
                # A new visit drops everything forward, like nvim's jumplist.
                entries = entries[: index + 1] if index >= 0 else []
                entries.append(workspace_id)
                state["entries"] = entries[-MAX_ENTRIES:]
                state["index"] = len(state["entries"]) - 1
                save_state(state)


        def forget_visit(workspace_id):
            with state_lock():
                state = load_state()
                entries = state["entries"]
                index = state["index"]
                if workspace_id not in entries:
                    return
                position = entries.index(workspace_id)
                del entries[position]
                if position <= index:
                    index -= 1
                state["index"] = index
                save_state(state)


        def jump(direction):
            workspaces = list_workspaces()
            live = {ws["workspace_id"] for ws in workspaces}
            current = focused_id(workspaces)
            if current is None:
                return 0
            with state_lock():
                state = load_state()
                entries = [ws for ws in state["entries"] if ws in live]
                index = state["index"]
                if current in entries:
                    index = entries.index(current)
                else:
                    # Closed workspaces were pruned above; the focused one is the
                    # position to navigate from.
                    index = index + 1 if 0 <= index <= len(entries) else len(entries)
                    entries = entries[:index]
                    entries.append(current)
                    index = len(entries) - 1
                target_index = index + direction
                if not 0 <= target_index < len(entries):
                    state.update(entries=entries, index=index)
                    save_state(state)
                    return 0
                target = entries[target_index]
                pending = prune_pending(state.get("pending") or {}, time.time())
                pending[target] = time.time()
                state.update(entries=entries, index=target_index, pending=pending)
                save_state(state)
            call("workspace.focus", {"workspace_id": target})
            return 0


        def handle_event(line):
            if not line:
                return
            try:
                message = json.loads(line)
            except ValueError:
                return
            event = message.get("event")
            data = message.get("data") or {}
            workspace_id = data.get("workspace_id")
            if not workspace_id:
                return
            if event == "workspace_focused":
                record_visit(workspace_id)
            elif event == "workspace_closed":
                forget_visit(workspace_id)


        def daemon():
            subscriptions = {
                "subscriptions": [
                    {"type": "workspace.focused"},
                    {"type": "workspace.closed"},
                ]
            }
            delay = 0.5
            while True:
                try:
                    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                        sock.connect(SOCKET_PATH)
                        sock.sendall(
                            (
                                json.dumps(
                                    {
                                        "id": "subscribe",
                                        "method": "events.subscribe",
                                        "params": subscriptions,
                                    }
                                )
                                + "\n"
                            ).encode()
                        )
                        delay = 0.5
                        # herdr does not replay the current focus on subscribe and may
                        # start after this service, so seed the focused workspace and
                        # reconnect loop; record_visit is a no-op when state already
                        # points there, so a restart keeps the history.
                        current = focused_id(list_workspaces())
                        if current:
                            record_visit(current)
                        with sock.makefile("r", encoding="utf-8") as reader:
                            for line in reader:
                                handle_event(line.strip())
                except (OSError, RuntimeError):
                    pass
                time.sleep(delay)
                delay = min(delay * 2, 5.0)


        def main(argv):
            command = argv[1] if len(argv) > 1 else ""
            if command == "daemon":
                daemon()
                return 0
            if command in ("back", "forward"):
                try:
                    return jump(-1 if command == "back" else 1)
                except (OSError, RuntimeError):
                    return 1
            print("usage: herdr-workspace-history {daemon|back|forward}", file=sys.stderr)
            return 2


        if __name__ == "__main__":
            sys.exit(main(sys.argv))
      '';

      herdrWorkspaceHistory = pkgs.writeShellApplication {
        name = "herdr-workspace-history";
        runtimeInputs = [ pkgs.python3 ];
        text = "exec python3 ${herdrWorkspaceHistoryPy} \"$@\"";
      };

      # `prefix+shift+m`: rename a workspace's project directory and its label in
      # one step, so a project keeps one name everywhere. Only the name part after
      # herdr-pane-name's `<number>:` prefix is replaced. The directory rename is a
      # rename(2): open shells keep working but their $PWD string goes stale.
      herdrWorkspaceRename = pkgs.writeShellApplication {
        name = "herdr-workspace-rename";
        runtimeInputs = with pkgs; [
          coreutils
          fzf
          herdr
          jq
        ];
        text = ''
          project_root="$HOME/projects"

          ws=$(herdr workspace list \
            | jq -r '.result.workspaces[] | select(.focused) | .workspace_id' \
            | head -n 1)
          if [[ -z $ws ]]; then
            echo "herdr-workspace-rename: no focused workspace" >&2
            exit 1
          fi

          label=$(herdr workspace list \
            | jq -r --arg w "$ws" '.result.workspaces[] | select(.workspace_id == $w) | .label')
          prefix=""
          name="$label"
          if [[ $label =~ ^([0-9]+:)(.+)$ ]]; then
            prefix="''${BASH_REMATCH[1]}"
            name="''${BASH_REMATCH[2]}"
          fi

          # Take the project from the focused pane, keeping only its first
          # component below ~/projects, so a shell inside a subdirectory still
          # renames the project itself.
          dir=$(herdr pane list | jq -r --arg w "$ws" '
            [ .result.panes[] | select(.workspace_id == $w) ]
            | (map(select(.focused)) + .)[0]
            | (.foreground_cwd // .cwd // empty)')
          old=""
          case "$dir" in
            "$project_root"/*)
              rest="''${dir#"$project_root"/}"
              candidate="''${rest%%/*}"
              # Only a directory that still exists counts: a previous run may have
              # moved it while the pane's PWD went stale.
              if [[ -d $project_root/$candidate ]]; then
                old="$candidate"
              fi
              ;;
          esac
          # A workspace outside ~/projects (e.g. /etc/nixos) only gets its label
          # renamed, unless a project of that name exists.
          if [[ -z $old && -d $project_root/$name ]]; then
            old="$name"
          fi

          current="''${old:-$name}"
          # fzf prints the typed query first: Enter on the prefill is a no-op and
          # clearing the line cancels.
          fzf_out=$(printf '%s\n' "$current" \
            | fzf --print-query --query "$current" --no-info \
                --header "rename $project_root/$current and the workspace label") || true
          new=$(printf '%s\n' "$fzf_out" | head -n 1)
          new="''${new// /-}"
          new="''${new//./_}"
          if [[ -z $new || $new == "$current" ]]; then
            exit 0
          fi
          case "$new" in
            . | .. | */*)
              echo "herdr-workspace-rename: invalid name: $new" >&2
              exit 1
              ;;
          esac

          if [[ -n $old && $old != "$new" ]]; then
            if [[ -e $project_root/$new ]]; then
              echo "herdr-workspace-rename: $project_root/$new already exists" >&2
              exit 1
            fi
            mv -- "$project_root/$old" "$project_root/$new"
            echo "moved $project_root/$old -> $project_root/$new"
            echo "open panes keep the old path; reopen tabs for a live cwd"
          fi

          herdr workspace rename "$ws" "$prefix$new"
          echo "workspace renamed to $prefix$new"
        '';
      };

      # Same role as tmux.nix's `ta`, but for herdr.
      ha = pkgs.writeShellScriptBin "ha" ''
        exec herdr-sessionizer "$@"
      '';

      # `hr <ssh-target>` attaches to a remote herdr server. The flag follows the
      # target, and only `server` mode has the prefix+f popup: herdr strips
      # command bindings from a client's local profile.
      hr = pkgs.writeShellScriptBin "hr" ''
        exec herdr --remote "$@" --remote-keybindings server
      '';

      # Claude Code's integration is a `SessionStart` hook, not an in-process
      # extension: it reports the session id + transcript path so herdr can run
      # `claude --resume <id>` after a restart. The store copy is mode 444, so nix
      # installs an executable copy; the hook entry itself lives in the unmanaged
      # ~/.claude/settings.json — `herdr integration status` should not report a
      # missing hook.
      herdrClaudeHook = pkgs.runCommandLocal "herdr-claude-hook" { } ''
        install -Dm555 ${pkgs.herdr}/share/herdr/integrations/claude/herdr-agent-state.sh $out
      '';
    in
    {
      # `hc` for the mobile app; desktops only (herdrCoreHosts).
      home.packages =
        lib.optionals (builtins.elem osConfig.networking.hostName herdrCoreHosts) [ pkgs.herdr-core ]
        ++ [
          herdrSessionizer
          herdrAgentizer
          herdrPaneizer
          ha
          hr
          herdrPaneName
          herdrWorkspaceHistory
          herdrWorkspaceRename
        ];

      # Updates pane/tab names right after a command starts and finishes; without
      # it they only refresh on lifecycle/focus events.
      xdg.configFile."fish/conf.d/herdr-pane-name.fish".source = herdrPaneNameFishHook + "/fish.fish";

      # Keeps the workspace visit history up to date for ctrl+shift+o / ctrl+shift+i.
      systemd.user.services.herdr-workspace-history = {
        Install.WantedBy = [ "graphical-session.target" ];
        Unit = {
          Description = "Track herdr workspace focus history for the ctrl+shift+o/i jumplist";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${herdrWorkspaceHistory}/bin/herdr-workspace-history daemon";
          Restart = "always";
          RestartSec = 2;
        };
      };

      home.activation.herdrPaneName = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${lib.getExe pkgs.herdr} plugin list \
          | grep -q 'herdr.pane-name.*${herdrPaneNamePlugin}' \
          || ${lib.getExe pkgs.herdr} plugin link ${herdrPaneNamePlugin} > /dev/null
      '';

      # herdr resumes agent conversations after a server restart (restored panes
      # without a native session ref come back as plain shells). This is herdr's
      # own pi integration, shipped in the package; `herdr integration install pi`
      # would write the same file, so nix owns it. Re-check on upgrades (integration
      # version must stay >= 2).
      home.file.".pi/agent/extensions/herdr-agent-state.ts".source =
        "${pkgs.herdr}/share/herdr/integrations/pi/herdr-agent-state.ts";
      home.file.".claude/hooks/herdr-agent-state.sh".source = herdrClaudeHook;

      programs.herdr = {
        enable = true;
        settings = {
          onboarding = false;

          # tmux used the catppuccin (macchiato) plugin.
          theme.name = "catppuccin";

          terminal.new_cwd = "follow";
          ui.mouse_capture = true; # tmux: `set -g mouse on`

          # Replay recent pane output after a restart; off upstream because output
          # can hold secrets, and the session dir is private already. This is what
          # makes a restored agent pane readable before the agent resumes.
          experimental.pane_history = true;

          keys = {
            prefix = "ctrl+space"; # tmux: C-Space

            # The Cmd+Shift chord is the macOS one (alt+shift is awkward there).
            # Bound everywhere so a darwin client on --remote-keybindings server
            # still gets it; no linux keyboard has a cmd key.
            previous_tab = [
              "alt+shift+h"
              "shift+cmd+h"
            ];
            next_tab = [
              "alt+shift+l"
              "shift+cmd+l"
            ];

            # Move the focused tab toward the front/back of the sidebar.
            # swap_pane_* is the pane-level equivalent, useless here because every
            # tab holds one full-width pane.
            move_tab_previous = "ctrl+shift+h";
            move_tab_next = "ctrl+shift+l";

            # Navigate mode (prefix+g): keys are mode-local, defaults are j/k = pane
            # down/up and arrows = workspace. This swaps them to vim-style; h/l stay
            # as permanent pane aliases.
            navigate_workspace_up = "k";
            navigate_workspace_down = "j";
            navigate_pane_up = "up";
            navigate_pane_down = "down";

            # A list replaces herdr's default, so prefix+h/j/k/l is repeated.
            focus_pane_left = [ "ctrl+alt+h" "prefix+h" ];
            focus_pane_down = [ "ctrl+alt+j" "prefix+j" ];
            focus_pane_up = [ "ctrl+alt+k" "prefix+k" ];
            focus_pane_right = [ "ctrl+alt+l" "prefix+l" ];

            # herdr 0.9.3 defines swap_pane_* but ships no default bindings.
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
              # Workspace jumplist (see herdrWorkspaceHistory). prefix+o/i are the
              # reliable chords (prefix+o overrides keys.open_notification_target);
              # ctrl+shift+o/i need the kitty keyboard protocol.
              {
                key = "prefix+o";
                type = "shell";
                command = "${herdrWorkspaceHistory}/bin/herdr-workspace-history back";
                description = "Go to the previously visited workspace";
              }
              {
                key = "prefix+i";
                type = "shell";
                command = "${herdrWorkspaceHistory}/bin/herdr-workspace-history forward";
                description = "Go forward in the workspace visit history";
              }
              {
                key = "ctrl+shift+o";
                type = "shell";
                command = "${herdrWorkspaceHistory}/bin/herdr-workspace-history back";
                description = "Go to the previously visited workspace";
              }
              {
                key = "ctrl+shift+i";
                type = "shell";
                command = "${herdrWorkspaceHistory}/bin/herdr-workspace-history forward";
                description = "Go forward in the workspace visit history";
              }
              {
                key = "prefix+p";
                type = "popup";
                command = "herdr-paneizer";
                width = "80%";
                height = "80%";
              }
              # Rename `~/projects/<name>` and the workspace label together.
              {
                key = "prefix+shift+m";
                type = "popup";
                command = "herdr-workspace-rename";
                width = "60%";
                height = "30%";
              }
            ];
          };
        };
      };
    };

  # The headless server must live in the GUI login session: one spawned by
  # an SSH attach (remote-client-bridge) inherits the ssh audit session, and
  # pam_tid.so then refuses Touch ID for sudo in every pane. A launchd agent
  # owns the server so remote bridges can only attach, never spawn it.
  flake.modules.darwin.gui =
    { config, pkgs, ... }:
    let
      herdrGuiServer = pkgs.writeShellApplication {
        name = "herdr-gui-server";
        runtimeInputs = [ pkgs.herdr ];
        text = ''
          # Take over a server spawned elsewhere (e.g. by a remote attach),
          # then run in this agent's GUI-session context. `stop` fails when
          # no server runs, hence `|| true`.
          herdr server stop || true
          sleep 1
          exec herdr server
        '';
      };
    in
    {
      launchd.user.agents.herdr = {
        command = "${herdrGuiServer}/bin/herdr-gui-server";
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
    };
}
