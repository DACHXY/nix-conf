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
            fzf_out=$( (
              find "$HOME/projects" "$HOME/notes" -mindepth 1 -maxdepth 1 -type d 2> /dev/null
              printf '%s\n' "$extra_dir"
            ) | fzf --print-query --header='select a project, or type a git URL to clone' )
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

            zoom = "prefix+m"; # tmux: prefix+m

            command = [
              {
                key = "prefix+f";
                type = "popup";
                command = "herdr-sessionizer";
                width = "80%";
                height = "80%";
              }
            ];
          };
        };
      };
    };
}
