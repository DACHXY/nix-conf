{ inputs, ... }:
{
  flake.modules.homeManager.base =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system isDarwin;
      inherit (lib) getExe;

      yaziOfficalPlugins = pkgs.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "plugins";
        rev = "main";
        hash = "sha256-TUS+yXxBOt6tL/zz10k4ezot8IgVg0/2BbS8wPs9KcE=";
      };

      compressYazi = pkgs.fetchFromGitHub {
        owner = "kkv9";
        repo = "compress.yazi";
        rev = "main";
        hash = "sha256-Mby185FCJY6nqHcHDQu+D5SLk+wGcyeUHK8yAvrd4TM=";
      };

      md2html = pkgs.callPackage ../scripts/md2html.nix { };
      pdfNormalize = pkgs.writeShellScriptBin "normalize-pdf" ''
        # Nomalize pdf to A4 size
        for path in "$@"; do
          output_path="normalized_$(basename "$path")"
          ${pkgs.ghostscript}/bin/gs \
             -o "$output_path" \ -sDEVICE=pdfwrite \ -sPAPERSIZE=a4 \ -dFIXEDMEDIA \
             -dPDFFitPage "$path"
        done
      '';

      pdfCombine = pkgs.writeShellScriptBin "combine-pdf" ''
        ${lib.getExe pkgs.pdftk} "$@" cat output combined_$(date +%Y%m%d_%H%M%S).pdf
      '';

      # `yj` — sessionizer-style jumper for yazi: pick a folder with fzf and open
      # it in a new yazi tab. yazi's `shell` child has no tty unless it is run
      # with `--block`, which is how the keymap calls it, so fzf draws straight
      # in the pane. Anywhere else without a tty falls back to a tmux popup, then
      # a tmux window, then plain `yazi <path>`.
      yaziJumper = pkgs.writeShellScriptBin "yj" ''
        list_cands() {
            find "$HOME/projects" -mindepth 1 -maxdepth 1 -type d
            find "$HOME/Pictures" -mindepth 1 -maxdepth 1 -type d
            printf '%s\n' "$HOME/notes" "$HOME/Downloads"
        }

        if [[ $# -eq 1 ]]; then
            selected=$1
        elif [[ -t 0 ]]; then
            selected=$(list_cands | sort | fzf --header='yazi jumper')
        elif [[ -n ''${TMUX:-} ]]; then
            dir=$(mktemp -d)
            list_cands | sort >"$dir/cands"
            : >"$dir/pick"
            tmux display-popup -w 70% -h 60% \
                -E "fzf --header='yazi jumper' < '$dir/cands' > '$dir/pick'" || true
            selected=$(cat "$dir/pick")
            rm -rf "$dir"
        else
            exit 0
        fi

        [[ -n $selected ]] || exit 0

        # `ya exec` silently no-ops for the calling instance, but `ya emit`
        # (DDS event) reaches it and `tab_create <url>` opens + focuses the tab.
        if [[ -n ''${YAZI_ID:-} ]]; then
            ya emit tab_create "$selected"
        elif [[ -n ''${TMUX:-} ]]; then
            # -c sets the window's cwd so it also survives yazi exiting.
            exec tmux new-window -c "$selected" yazi
        else
            exec yazi "$selected"
        fi
      '';
    in
    {
      home.packages = with pkgs; [
        pdfNormalize
        yaziJumper
        rar
        gzip
        mediainfo
        exiftool
      ];

      programs.yazi = {
        enable = true;
        package = inputs.yazi.packages.${system}.default.override {
          _7zz = pkgs._7zz-rar;
        };
        shellWrapperName = "y";
        enableFishIntegration = true;

        plugins = {
          toggle-pane = "${yaziOfficalPlugins}/toggle-pane.yazi";
          mount = "${yaziOfficalPlugins}/mount.yazi";
          zoom = "${yaziOfficalPlugins}/zoom";
          vcs-files = "${yaziOfficalPlugins}/vcs-files";
          git = "${yaziOfficalPlugins}/git";
          compress = "${compressYazi}";
        };

        settings = {
          input = {
            cursor_blink = true;
          };

          opener = {
            edit = [
              {
                run = "nvim %s";
                desc = "neovim";
                block = true;
              }
            ];

            player = [
              { run = if isDarwin then "open %s" else "${getExe pkgs.mpv} --force-window %s"; }
            ];

            open = [
              {
                run = "xdg-open %s";
                desc = "Open";
              }
            ];
          };

          open = {
            prepend_rules = [
              {
                mime = "application/pdf";
                use = "open";
              }
            ];
          };
        };

        keymap = {
          mgr.prepend_keymap = [
            # Git Changes
            {
              on = [
                "g"
                "c"
              ];
              run = "plugin vcs-files";
              desc = "Show Git file changes";
            }
            # Image zoom
            {
              on = "+";
              run = "plugin zoom 1";
              desc = "Zoom in hovered file";
            }
            {
              on = "-";
              run = "plugin zoom -1";
              desc = "Zoom out hovered file";
            }
            # Mount Manager
            {
              on = "M";
              run = "plugin mount";
              desc = "Launch mount manager";
              # Usage
              # Key binding 	Alternate key 	Action
              # q 	- 	Quit the plugin
              # k 	↑ 	Move up
              # j 	↓ 	Move down
              # l 	→ 	Enter the mount point
              # m 	- 	Mount the partition
              # u 	- 	Unmount the partition
              # e 	- 	Eject the disk
            }
            # Toggle Maximize Preview
            {
              on = "T";
              run = "plugin toggle-pane max-preview";
              desc = "Show or hide the preview panel";
            }
            # cd back to the root of the current Git repository
            {
              on = [
                "g"
                "r"
              ];
              run = ''shell -- ya emit cd "$(git rev-parse --show-toplevel)"'';
              desc = "Go to git root";
            }
            # Jump to a project note/picture folder in a new tab
            {
              on = [
                "g"
                "j"
              ];
              run = "shell --block -- yj";
              desc = "Jump to a folder in a new tab (fzf)";
            }
            # Compress
            {
              on = [
                "c"
                "a"
                "a"
              ];
              run = "plugin compress";
              desc = "Archive selected files";
            }
            {
              on = [
                "c"
                "a"
                "p"
              ];
              run = "plugin compress -p";
              desc = "Archive selected files (password)";
            }
            # Start terminal
            {
              on = [ "!" ];
              for = "unix";
              run = ''shell "$SHELL" --block'';
              desc = "Open $SHELL here";
            }
            # Combine PDF
            {
              on = [
                "F" # file
                "p" # pdf
                "c" # combine
              ];
              for = "unix";
              run = ''shell -- ${lib.getExe pdfCombine} "%h"'';
              desc = "Combine selected pdf";
            }
            {
              on = [
                "F" # file
                "p" # pdf
                "n" # normalize
              ];
              for = "unix";
              run = ''shell -- ${lib.getExe pdfNormalize} "%h" 2>/dev/null'';
              desc = "Normalize PDF to A4 size";
            }
            {
              on = [
                "F" # file
                "H" # html
              ];
              for = "unix";
              run = [
                ''shell -- for path in "%s"; do ${lib.getExe md2html} "$path"; done''
              ];
              desc = "Convert Markdown to HTML";
            }
          ];
        };

        initLua =
          # lua
          ''
            -- Show user/group of files in status bar
            Status:children_add(function()
              local h = cx.active.current.hovered
              if not h or ya.target_family() ~= "unix" then
                return ""
              end

              return ui.Line {
                ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
                ":",
                ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
                " ",
              }
            end, 500, Status.RIGHT)
          '';
      };

    };

  flake.modules.darwin.gui =
    { config, pkgs, ... }:
    let
      setWallpaper = pkgs.writeShellScript "set-wallpaper" ''
        osascript -e 'tell application "Finder" to set desktop picture to POSIX file "$@"'
      '';
    in
    {
      home-manager.users.${config.my.user.name} = {
        programs.yazi.keymap.mgr.prepend_keymap = [
          # Set Wallpaper
          {
            on = [
              "g"
              "w"
            ];
            run = ''shell '${setWallpaper} "%h" 2>&1 >/dev/null' '';
            desc = "Set as wallpaper";
          }

          # Copy selected files to the system clipboard while yanking
          {
            on = "y";
            run = [
              ''shell -- for path in "%s"; do echo -n "file://$path"; done | pbcopy''
              "yank"
            ];
          }

          # Drag and Drop
          {
            on = [
              "c"
              "D"
            ];
            run = "shell -- open -R %h";
            desc = "Drag the file";
          }
        ];
      };
    };

  flake.modules.nixos.gui =
    { config, pkgs, ... }:
    let
      setWallpaper = ''shell 'noctalia msg wallpaper-set "$0"  2>&1 >/dev/null' '';
    in
    {
      home-manager.users.${config.my.user.name} = {
        home.packages = with pkgs; [
          ueberzugpp
          ripdrag
        ];

        programs.yazi.keymap.mgr.prepend_keymap = [
          # Set Wallpaper
          {
            on = [
              "g"
              "w"
            ];
            run = ''shell '${setWallpaper} "%h" 2>&1 >/dev/null' '';
            desc = "Set as wallpaper";
          }

          # Copy selected files to the system clipboard while yanking
          {
            on = "y";
            run = [
              ''shell -- for path in "%s"; do echo -n "file://$path"; done | wl-copy -t text/uri-list''
              "yank"
            ];
          }

          # Drag and Drop
          {
            on = [
              "c"
              "D"
            ];
            run = "shell -- ripdrag -x %s";
            desc = "Drag the file";
          }
        ];
      };

    };

  # AirDrop send from yazi. Scoped to dn-cscc, the only host that runs the
  # owly radio/receive services (modules/hosts/dn-cscc/owly.nix), so no other
  # host gets a keymap that shells out to a binary it does not have.
  flake.modules.nixos.yazi-airdrop =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      owly = lib.getExe config.services.owly.package;
      fzf = lib.getExe pkgs.fzf;

      airdrop = pkgs.writeShellScriptBin "yazi-airdrop" ''
        if [[ $# -eq 0 ]]; then
            echo "No files selected" >&2
            exit 1
        fi

        echo "Looking for nearby AirDrop receivers (takes 10-20 s)…" >&2
        list=$(mktemp)
        trap 'rm -f "$list"' EXIT
        ${owly} browse 2>/dev/null | while read -r id rest; do
            [[ $id =~ ^[0-9a-f]{12}$ ]] || continue
            printf '%s\t%s\n' "$id" "''${rest%% (*}"
        done >"$list"

        if [[ ! -s $list ]]; then
            echo "No receiver found: make sure the other device is unlocked and its AirDrop is set to \"Everyone\" or \"Contacts Only\"." >&2
            read -r -p "Press Enter to close" _ || true
            exit 1
        fi

        pick=$(${fzf} --delimiter=$'\t' --with-nth=2 --header='AirDrop receiver' <"$list") || exit 0
        ${owly} send --to "''${pick%%$'\t'*}" -- "$@"
        read -r -p "Press Enter to close" _ || true
      '';
    in
    {
      home-manager.users.${config.my.user.name} = {
        home.packages = [
          airdrop
          pkgs.fzf
        ];

        programs.yazi.keymap.mgr.prepend_keymap = [
          # AirDrop the selection (or the hovered file) to a nearby device.
          {
            on = [
              "g"
              "a"
            ];
            run = "shell --block -- yazi-airdrop %s";
            desc = "AirDrop selected files";
          }
        ];
      };
    };
}
