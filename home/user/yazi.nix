{
  inputs,
  system,
  pkgs,
  ...
}:
let
  yaziPlugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "main";
    hash = "sha256-TUS+yXxBOt6tL/zz10k4ezot8IgVg0/2BbS8wPs9KcE=";
  };
in
{
  programs = {
    yazi = {
      enable = true;
      package = inputs.yazi.packages.${system}.default;
      shellWrapperName = "y";
      enableFishIntegration = true;

      plugins = {
        toggle-pane = ''${yaziPlugins}/toggle-pane.yazi'';
        mount = ''${yaziPlugins}/mount.yazi'';
        zoom = ''${yaziPlugins}/zoom'';
        vcs-files = ''${yaziPlugins}/vcs-files'';
        git = ''${yaziPlugins}/git'';
      };

      settings = {
        plugin.prepend_fetchers = [
          {
            id = "git";
            name = "*";
            run = "git";
          }
          {
            id = "git";
            name = "*/";
            run = "git";
          }
        ];

        input = {
          cursor_blink = true;
        };

        opener = {
          edit = [
            {
              run = ''''\${EDITOR:=nvim} "$@"'';
              desc = "$EDITOR";
              block = true;
            }
            {
              run = ''code "$@"'';
              orphan = true;
            }
          ];

          player = [
            { run = ''mpv --force-window "$@"''; }
          ];
        };
      };

      keymap = {
        mgr = {
          prepend_keymap = [
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
              desc = "Show or hide the preview pane";
            }
            # Copy selected files to the system clipboard while yanking
            {
              on = "y";
              run = [
                ''shell -- for path in "$@"; do echo "file://$path"; done | wl-copy -t text/uri-list''
                "yank"
              ];
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
            # Drag and Drop
            {
              on = [
                "c"
                "D"
              ];
              run = ''
                shell '${pkgs.ripdrag.out}/bin/ripdrag "$@" -x 2>/dev/null &' --confirm
              '';
              desc = "Drag the file";
            }
            # Start terminal
            {
              on = [ "!" ];
              for = "unix";
              run = ''shell "$SHELL" --block'';
              desc = "Open $SHELL here";
            }
          ];
        };
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

  home.packages = with pkgs; [
    ueberzugpp
  ];
}
