{
  # Upstream projects every focus request on the public API socket onto all
  # attached clients, so a popup like herdr-sessionizer switched every client's
  # workspace. The patch scopes such a request to one client: while a popup is
  # open, the client that opened the popup wins; otherwise the foreground
  # client (the one whose pane the `ha`/`herdr workspace focus` command was
  # typed in) moves alone, falling back to the upstream all-clients behaviour
  # when no shell client is foreground. Re-check it on herdr upgrades.
  # Pi panes came back as plain shells after a server restart, for two reasons.
  # Pi-Bolt ships its own herdr integration that reports source `pi-bolt` with
  # the session file, which is not in herdr's is_official_agent_source
  # whitelist, and `pi-bolt` is not a known agent label. Behind that, herdr
  # parks the first session report of a fresh pane until a second report
  # arrives, and Pi only reports on state changes, so no ref was ever anchored
  # (this broke plain `pi` panes too). The patch aliases the `pi-bolt` source to
  # `herdr:pi`, maps the label onto the `pi` agent (restore command is
  # `pi --session <file>`), and anchors the first report when the agent process
  # is present. Verified end-to-end against a throwaway session: the pane comes
  # back on the same session file. Re-check it on herdr upgrades.
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

      # Upstream's fish hook launches its background jobs without `disown`, so an
      # interactive `exit` refuses with "There are still jobs active". Disown each
      # job right after it starts — suppressing the "no suitable jobs" error when
      # it already finished — so the shell stops tracking it.
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
            # fzf exits 1 when the query matches nothing — accepting that query
            # is exactly how a clone URL gets entered, so it must not trip errexit.
            fzf_out=$( (
              find "$HOME/projects" "$HOME/notes" -mindepth 1 -maxdepth 1 -type d 2> /dev/null
              printf '%s\n' "$extra_dir"
            ) | fzf --print-query --header='select a project, or type a git URL to clone [optional folder name]' ) || true
            # fzf prints the typed query first, then the chosen match if any.
            # An unmatched query is how a clone URL gets entered.
            selected=$(printf '%s\n' "$fzf_out" | tail -n +2)
            [[ -z $selected ]] && selected=$(printf '%s\n' "$fzf_out" | head -n 1)
          fi

          # A git-cloneable address clones into ~/projects first, then flows
          # through the same workspace-name/path logic below. A second
          # whitespace-separated word names the destination folder; without one
          # the URL's basename is used. The URL's own `.git` suffix and dots are
          # only stripped from that default, never from an explicit name.
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

          # A name typed that matches no existing directory is a new project:
          # create it under ~/projects, then fall through to the switch logic.
          if [[ ! -d $selected ]]; then
            selected="$HOME/projects/$(basename "$selected" | tr . _)"
            mkdir -p "$selected"
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

      # nvim-style jumplist for workspaces: `back` / `forward` walk the order in
      # which workspaces were actually visited, the way ctrl+o / ctrl+i walk
      # nvim's changelist. herdr only offers `previous_workspace`, which cycles
      # through sidebar order (actions.rs: previous_workspace -> next_workspace,
      # an index +/-1 modulo the workspace list) and has no memory of recency, so
      # the visit history lives here.
      #
      # `daemon` subscribes to workspace.focused over the API socket (the same
      # newline-delimited JSON protocol the CLI uses) and maintains
      # entries/index in a state file. Jumps write the target into `pending`
      # before focusing, so the focus event they cause is not recorded as a new
      # visit — otherwise every jump would truncate the forward history.
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
                # A new visit drops everything the forward direction could reach,
                # exactly like nvim's jumplist.
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
                    # Closed workspaces were pruned above; make sure the focused
                    # one is the position we navigate from.
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
                        # herdr does not replay the current focus on subscribe, and
                        # it may start after this service, so seed the entry for
                        # whatever is focused now and reconnect in a loop instead
                        # of exiting. record_visit is a no-op when the state
                        # already points at that workspace, so a healthy restart
                        # keeps the history intact.
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

      # Claude Code's integration is a `SessionStart` hook rather than an
      # in-process extension: the script reports the session id + transcript
      # path so herdr can run `claude --resume <id>` after a server restart.
      # `herdr integration install claude` would write this very file, but the
      # store copy is mode 444, so nix installs an executable copy instead.
      # The matching hook entry lives in ~/.claude/settings.json, which is not
      # nix-managed: re-check it on upgrade (`herdr integration status` must not
      # report claude as missing its hook).
      herdrClaudeHook = pkgs.runCommandLocal "herdr-claude-hook" { } ''
        install -Dm555 ${pkgs.herdr}/share/herdr/integrations/claude/herdr-agent-state.sh $out
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
        herdrWorkspaceHistory
      ];

      # Updates pane/tab names right after a command starts and finishes; without
      # it names only refresh on herdr lifecycle/focus events.
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

      # herdr resumes agent conversations after a server restart (snapshot
      # restore brings the layout back, but panes without a native session
      # reference come back as plain shells). This is herdr's own pi
      # integration, which reports `agent_session_path`/`agent_session_id`
      # over the socket so herdr can run `pi --session <path>` on restore.
      # Shipped inside the herdr package; `herdr integration install pi` would
      # write the very same file, so nix owns it instead. Re-check on herdr
      # upgrades (integration version must stay >= 2).
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

          # Replay recent pane output after a server restart. Off upstream by
          # default because pane output can contain secrets/tokens; the herdr
          # session dir is private already, and it is what makes a restored
          # agent pane readable before the agent finishes resuming.
          experimental.pane_history = true;

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
              # nvim's ctrl+o / ctrl+i, but for workspaces (see herdrWorkspaceHistory).
              # prefix+o / prefix+i are the reliable chords; ctrl+shift+o / ctrl+shift+i
              # are kept as well, but they need the kitty keyboard protocol and never
              # fire on a terminal without it. Note prefix+o overrides herdr's default
              # keys.open_notification_target.
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
            ];
          };
        };
      };
    };
}
