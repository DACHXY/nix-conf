{
  inputs,
  config,
  system,
  pkgs,
  lib,
  ...
}:
let
  yaziPlugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "86d28e4fb4f25f36cc501b8cb0badb37a6b14263";
    hash = "sha256-m/gJTDm0cVkIdcQ1ZJliPqBhNKoCW1FciLkuq7D1mxo=";
  };
in
{
  programs = {
    yazi = {
      enable = true;
      package = inputs.yazi.packages.${system}.default;
      shellWrapperName = "y";
      enableFishIntegration = false;

      plugins = {
        toggle-panel = ''${yaziPlugins}/toggle-panel.yazi'';
      };

      flavors = {
        gruvbox-dark = pkgs.fetchFromGitHub {
          owner = "bennyyip";
          repo = "gruvbox-dark.yazi";
          rev = "91fdfa70f6d593934e62aba1e449f4ec3d3ccc90";
          hash = "sha256-RWqyAdETD/EkDVGcnBPiMcw1mSd78Aayky9yoxSsry4=";
        };
      };

      theme = {
        flavors = {
          dark = "gruvbox-dark";
          light = "gruvbox-dark";
        };
      };

      keymap = {
        mgr = {
          prepend_keymap = [
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
          -- Show symlink in status bar
          Status:children_add(function(self)
            local h = self._current.hovered
            if h and h.link_to then
              return " -> " .. toString(h.link_to)
            else
              return ""
            end
          end, 3300, Status.LEFT)

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

          -- Show username and hostname in header
          Header:children_add(function()
            if ya.target_family() ~= "unix" then
              return ""
            end
            return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
          end, 500, Header.LEFT)
        '';
    };
  };

  home.packages = with pkgs; [
    ueberzugpp
  ];

  # xdg.portal = {
  #   enable = lib.mkForce true;
  #   extraPortals = [ pkgs.xdg-desktop-portal-termfilechooser ];
  #   config = {
  #     common.default = [
  #       "hyprland"
  #       "gtk"
  #     ];
  #     common = {
  #       "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
  #     };
  #     hyprland.default = [
  #       "hyprland"
  #       "gtk"
  #     ];
  #     hyprland."org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
  #   };
  # };

  # xdg.configFile."xdg-desktop-portal-termfilechooser/config" = {
  #   force = true;
  #   text = ''
  #     [filechooser]
  #     cmd=TERMCMD='${config.programs.ghostty.package}/bin/ghostty --title=file_chooser -e "bash -c ${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh"'
  #     default_dir=$HOME
  #     open_mode = suggested
  #     save_mode = last
  #   '';
  # };

  # home.sessionVariables.TERMCMD = "${config.programs.ghostty.package}/bin/ghostty --title=file_chooser";
}
