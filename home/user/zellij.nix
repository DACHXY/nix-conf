{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (builtins) fetchurl;
  inherit (config.lib.stylix) colors;
  inherit (lib) getExe;

  zjstatus = fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm";
    sha256 = "sha256:06mfcijmsmvb2gdzsql6w8axpaxizdc190b93s3nczy212i846fw";
  };

  zellij-switch = fetchurl {
    url = "https://github.com/mostafaqanbaryan/zellij-switch/releases/download/0.2.1/zellij-switch.wasm";
    sha256 = "sha256:1bi219dh9dfs1h7ifn4g5p8n6ini8ack1bfys5z36wzbzx0pw9gg";
  };

  zellij-sessionizer-src = fetchurl {
    url = "https://raw.githubusercontent.com/dachxy/zellij-sessionizer/refs/heads/main/zellij-sessionizer";
    sha256 = "sha256:01az9blb86mc3lxaxnrfcj23jaxhagsbs31qjn6pj5wm1wgb2mrf";
  };

  zellij-sessionizer = pkgs.writeShellScriptBin "zellij-sessionizer" ''
    export PATH="$PATH:${pkgs.fzf}/bin"
    export ZELLIJ_SESSIONIZER_SEARCH_PATHS="$HOME/projects $HOME/notes $HOME/expr"
    export ZELLIJ_SESSIONIZER_SPECIFIC_PATHS="/etc/nixos"
    export ZELLIJ_SESSIONIZER_SWITCH_PLUGIN="file:${zellij-switch}"

    bash ${zellij-sessionizer-src}
  '';
in
{
  home.packages = [
    zellij-sessionizer
  ];

  programs.fish.shellAliases = {
    al = "zellij";
    aa = "zellij a --index 0";
    zs = "zellij-sessionizer";
  };

  programs.zellij = {
    enable = true;
    attachExistingSession = true;
    enableFishIntegration = true;
    enableBashIntegration = true;

    settings = {
      pane_frames = false;
      show_startup_tips = false;
      session_serialization = false;
      default_layout = "default-com";
    };

    extraConfig = ''
      keybinds clear-defaults=true {
        shared {
          bind "Ctrl /" { ToggleFloatingPanes; SwitchToMode "Normal"; }
        }
        normal {
          bind "Ctrl n" { SwitchToMode "Resize"; }
          bind "Ctrl p" { SwitchToMode "Pane"; }
          bind "Ctrl [" { SwitchToMode "Scroll"; }
          bind "Ctrl m" { SwitchToMode "Move"; }
          bind "Ctrl t" { SwitchToMode "Tab"; }
          bind "Ctrl Space" {
            LaunchOrFocusPlugin "session-manager" {
              floating true
              move_to_focused_tab true
            };
            SwitchToMode "Normal"
          }
          bind "Ctrl f" { Run "${getExe zellij-sessionizer}" {
            close_on_exit true
            floating true
            x "30%"
            y "10%"
            width "40%"
            height "80%"
          }; SwitchToMode "locked"; }
          bind "Alt Shift h" { GoToPreviousTab; }
          bind "Alt Shift l" { GoToNextTab; }
          bind "Ctrl Shift o" { SwitchToMode "Session"; }
          bind "Ctrl Shift -" { Run "yazi" {
            floating true
            close_on_exit true
            width "80%"
            height "80%"
            x "10%"
            y "10%"
          };}
        }
        locked {
          bind "Ctrl g" { SwitchToMode "Normal"; }
        }
        resize {
          bind "Ctrl n" "Ctrl c" "Esc" { SwitchToMode "Normal"; }
          bind "h" "Left" { Resize "Increase Left"; }
          bind "j" "Down" { Resize "Increase Down"; }
          bind "k" "Up" { Resize "Increase Up"; }
          bind "l" "Right" { Resize "Increase Right"; }
          bind "H" { Resize "Decrease Left"; }
          bind "J" { Resize "Decrease Down"; }
          bind "K" { Resize "Decrease Up"; }
          bind "L" { Resize "Decrease Right"; }
          bind "=" "+" { Resize "Increase"; }
          bind "-" { Resize "Decrease"; }
        }
        pane {
          bind "Ctrl p" "Ctrl c" "Esc"  { SwitchToMode "Normal"; }
          bind "h" "Left" { MoveFocus "Left"; }
          bind "l" "Right" { MoveFocus "Right"; }
          bind "j" "Down" { MoveFocus "Down"; }
          bind "k" "Up" { MoveFocus "Up"; }
          bind "p" { SwitchFocus; }
          bind "n" { NewPane; SwitchToMode "Normal"; }
          bind "d" { NewPane "Down"; SwitchToMode "Normal"; }
          bind "r" { NewPane "Right"; SwitchToMode "Normal"; }
          bind "s" { NewPane "stacked"; SwitchToMode "Normal"; }
          bind "x" { CloseFocus; SwitchToMode "Normal"; }
          bind "F" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
          bind "f" { ToggleFloatingPanes; SwitchToMode "Normal"; }
          bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }
          bind "R" { SwitchToMode "RenamePane"; PaneNameInput 0;}
          bind "P" { TogglePanePinned; SwitchToMode "Normal"; }
          bind "g" { Run "${pkgs.lazygit}/bin/lazygit" {
            floating true
            close_on_exit true
            width "80%"
            height "80%"
            x "10%"
            y "10%"
          }; SwitchToMode "Normal"; }
        }
        move {
          bind "Ctrl m" "Ctrl c" "Esc" { SwitchToMode "Normal"; }
          bind "n" "Tab" { MovePane; }
          bind "p" { MovePaneBackwards; }
          bind "h" "Left" { MovePane "Left"; }
          bind "j" "Down" { MovePane "Down"; }
          bind "k" "Up" { MovePane "Up"; }
          bind "l" "Right" { MovePane "Right"; }
        }
        tab {
          bind "Ctrl t" "Ctrl c" "Esc" { SwitchToMode "Normal"; }
          bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
          bind "h" "Left" "Up" "k" { GoToPreviousTab; }
          bind "l" "Right" "Down" "j" { GoToNextTab; }
          bind "n" { NewTab; SwitchToMode "Normal"; }
          bind "x" { CloseTab; SwitchToMode "Normal"; }
          bind "s" { ToggleActiveSyncTab; SwitchToMode "Normal"; }
          bind "b" { BreakPane; SwitchToMode "Normal"; }
          bind "]" { BreakPaneRight; SwitchToMode "Normal"; }
          bind "[" { BreakPaneLeft; SwitchToMode "Normal"; }
          bind "1" { GoToTab 1; SwitchToMode "Normal"; }
          bind "2" { GoToTab 2; SwitchToMode "Normal"; }
          bind "3" { GoToTab 3; SwitchToMode "Normal"; }
          bind "4" { GoToTab 4; SwitchToMode "Normal"; }
          bind "5" { GoToTab 5; SwitchToMode "Normal"; }
          bind "6" { GoToTab 6; SwitchToMode "Normal"; }
          bind "7" { GoToTab 7; SwitchToMode "Normal"; }
          bind "8" { GoToTab 8; SwitchToMode "Normal"; }
          bind "9" { GoToTab 9; SwitchToMode "Normal"; }
          bind "Tab" { ToggleTab; }
        }
        scroll {
          bind "Ctrl [" { SwitchToMode "Normal"; }
          bind "e" { EditScrollback; SwitchToMode "Normal"; }
          bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
          bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
          bind "j" "Down" { ScrollDown; }
          bind "k" "Up" { ScrollUp; }
          bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
          bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
          bind "d" { HalfPageScrollDown; }
          bind "u" { HalfPageScrollUp; }
        }
        search {
          bind "Ctrl s" { SwitchToMode "Normal"; }
          bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
          bind "j" "Down" { ScrollDown; }
          bind "k" "Up" { ScrollUp; }
          bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
          bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
          bind "d" { HalfPageScrollDown; }
          bind "u" { HalfPageScrollUp; }
          bind "n" { Search "down"; }
          bind "shift n" { Search "up"; }
          bind "c" { SearchToggleOption "CaseSensitivity"; }
          bind "w" { SearchToggleOption "Wrap"; }
          bind "o" { SearchToggleOption "WholeWord"; }
        }
        entersearch {
          bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; }
          bind "Enter" { SwitchToMode "Search"; }
        }
        renametab {
          bind "Ctrl c" { SwitchToMode "Normal"; }
          bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
        }
        renamepane {
          bind "Ctrl c" { SwitchToMode "Normal"; }
          bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
        }
        session {
          bind "Ctrl o" "Ctrl c" { SwitchToMode "Normal"; }
          bind "Ctrl s" { SwitchToMode "Scroll"; }
          bind "d" { Detach; }
          bind "w" {
            LaunchOrFocusPlugin "session-manager" {
              floating true
              move_to_focused_tab true
            };
            SwitchToMode "Normal"
          }
          bind "c" {
            LaunchOrFocusPlugin "configuration" {
              floating true
              move_to_focused_tab true
            };
            SwitchToMode "Normal"
          }
          bind "p" {
            LaunchOrFocusPlugin "plugin-manager" {
              floating true
              move_to_focused_tab true
            };
            SwitchToMode "Normal"
          }
          bind "a" {
            LaunchOrFocusPlugin "zellij:about" {
              floating true
              move_to_focused_tab true
            };
            SwitchToMode "Normal"
          }
          bind "s" {
            LaunchOrFocusPlugin "zellij:share" {
              floating true
              move_to_focused_tab true
            };
            SwitchToMode "Normal"
          }
        }
      }
      plugins {
        tab-bar location="zellij:tab-bar"
        status-bar location="zellij:status-bar"
        strider location="zellij:strider"
        compact-bar location="zellij:compact-bar"
        session-manager location="zellij:session-manager"
        welcome-screen location="zellij:session-manager" {
            welcome_screen true
        }
        filepicker location="zellij:strider" {
            cwd "/"
        }
        configuration location="zellij:configuration"
        plugin-manager location="zellij:plugin-manager"
        about location="zellij:about"
      }
      web_client {
        font "monospace"
      }
    '';
    layouts = {
      default-com = {
        layout = {
          _children = [
            {
              swap_floating_layout._children = [
                {
                  floating_panes = {
                    _props = {
                      max_panes = 1;
                    };
                    _children = [
                      {
                        pane = {
                          x = "10%";
                          y = "10%";
                          height = "80%";
                          width = "80%";
                        };
                      }
                    ];
                  };
                }
              ];
            }
            {
              default_tab_template._children = [
                {
                  pane = {
                    size = 1;
                    borderless = true;
                    plugin = {
                      location = "file:${zjstatus}";
                      format_left = "{mode}#[bg=#${colors.base00}] {tabs}";
                      format_center = "";
                      format_right = "#[bg=#${colors.base00},fg=#${colors.base0D}]#[bg=#${colors.base0D},fg=#${colors.base01},bold] #[bg=#${colors.base02},fg=#${colors.base05},bold] {session} #[bg=#${colors.base03},fg=#${colors.base05},bold]";
                      format_space = "";
                      format_hide_on_overlength = "true";
                      format_precedence = "crl";

                      border_enabled = "false";
                      border_char = "─";
                      border_format = "#[fg=#6C7086]{char}";
                      border_position = "top";

                      mode_normal = "#[bg=#${colors.base0B},fg=#${colors.base02},bold] NORMAL#[bg=#${colors.base03},fg=#${colors.base0B}]█";
                      mode_locked = "#[bg=#${colors.base04},fg=#${colors.base02},bold] LOCKED #[bg=#${colors.base03},fg=#${colors.base04}]█";
                      mode_resize = "#[bg=#${colors.base08},fg=#${colors.base02},bold] RESIZE#[bg=#${colors.base03},fg=#${colors.base08}]█";
                      mode_pane = "#[bg=#${colors.base0D},fg=#${colors.base02},bold] PANE#[bg=#${colors.base03},fg=#${colors.base0D}]█";
                      mode_tab = "#[bg=#${colors.base07},fg=#${colors.base02},bold] TAB#[bg=#${colors.base03},fg=#${colors.base07}]█";
                      mode_scroll = "#[bg=#${colors.base0A},fg=#${colors.base02},bold] SCROLL#[bg=#${colors.base03},fg=#${colors.base0A}]█";
                      mode_enter_search = "#[bg=#${colors.base0D},fg=#${colors.base02},bold] ENT-SEARCH#[bg=#${colors.base03},fg=#${colors.base0D}]█";
                      mode_search = "#[bg=#${colors.base0D},fg=#${colors.base02},bold] SEARCHARCH#[bg=#${colors.base03},fg=#${colors.base0D}]█";
                      mode_rename_tab = "#[bg=#${colors.base07},fg=#${colors.base02},bold] RENAME-TAB#[bg=#${colors.base03},fg=#${colors.base07}]█";
                      mode_rename_pane = "#[bg=#${colors.base0D},fg=#${colors.base02},bold] RENAME-PANE#[bg=#${colors.base03},fg=#${colors.base0D}]█";
                      mode_session = "#[bg=#${colors.base0E},fg=#${colors.base02},bold] SESSION#[bg=#${colors.base03},fg=#${colors.base0E}]█";
                      mode_move = "#[bg=#${colors.base0F},fg=#${colors.base02},bold] MOVE#[bg=#${colors.base03},fg=#${colors.base0F}]█";
                      mode_prompt = "#[bg=#${colors.base0D},fg=#${colors.base02},bold] PROMPT#[bg=#${colors.base03},fg=#${colors.base0D}]█";
                      mode_tmux = "#[bg=#${colors.base09},fg=#${colors.base02},bold] TMUX#[bg=#${colors.base03},fg=#${colors.base09}]█";

                      tab_normal = "#[bg=#${colors.base03},fg=#${colors.base0D}]█#[bg=#${colors.base0D},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{floating_indicator}#[bg=#${colors.base03},fg=#${colors.base02},bold]█";
                      tab_normal_fullscreen = "#[bg=#${colors.base03},fg=#${colors.base0D}]█#[bg=#${colors.base0D},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{fullscreen_indicator}#[bg=#${colors.base03},fg=#${colors.base02},bold]█";
                      tab_normal_sync = "#[bg=#${colors.base03},fg=#${colors.base0D}]█#[bg=#${colors.base0D},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{sync_indicator}#[bg=#${colors.base03},fg=#${colors.base02},bold]█";

                      tab_active = "#[bg=#${colors.base03},fg=#${colors.base09}]█#[bg=#${colors.base09},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{floating_indicator}#[bg=#${colors.base03},fg=#${colors.base02},bold]█";
                      tab_active_fullscreen = "#[bg=#${colors.base03},fg=#${colors.base09}]█#[bg=#${colors.base09},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{fullscreen_indicator}#[bg=#${colors.base03},fg=#${colors.base02},bold]█";
                      tab_active_sync = "#[bg=#${colors.base03},fg=#${colors.base09}]█#[bg=#${colors.base09},fg=#${colors.base02},bold]{index} #[bg=#${colors.base02},fg=#${colors.base05},bold] {name}{sync_indicator}#[bg=#${colors.base03},fg=#${colors.base02},bold]█";

                      tab_separator = "#[bg=#${colors.base00}] ";

                      tab_sync_indicator = " ";
                      tab_fullscreen_indicator = " 󰊓";
                      tab_floating_indicator = " 󰹙";

                      command_git_branch_command = "git rev-parse --abbrev-ref HEAD";
                      command_git_branch_format = "#[fg=blue] {stdout} ";
                      command_git_branch_interval = "10";
                      command_git_branch_rendermode = "static";

                      datetime = "#[fg=#6C7086,bold] {format} ";
                      datetime_format = "%A, %d %b %Y %H:%M";
                      datetime_timezone = "Taiwan/Taipei";
                    };
                  };
                }
                { "children" = { }; }
              ];
            }
          ];
        };
      };
    };
  };
}
