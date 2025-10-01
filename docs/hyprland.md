# Hyprland

> $mod: Super

## Key Binds

The key binds are defined in [bind.nix](../home/user/hypr/bind.nix).

### Common

| Keys                    | Description                         |
| ----------------------- | ----------------------------------- |
| $mod + F                | Browser                             |
| $mod + Return           | Terminal                            |
| CTRL + ALT + T          | Terminal                            |
| $mod + Q                | Kill active window                  |
| $mod + M                | System Menu                         |
| $mod + E                | File explorer (Yazi)                |
| ALT + SPACE             | Application Launcher (rofi)         |
| $mod + W                | Change wallpaper (Input image link) |
| $mod + X                | Notification center                 |
| CTRL + $mod + SHIFT + L | Lock screen (hyprlock)              |
| $mod + C                | Visual Code (In case you need :D)   |

### Input Method

| Keys         | Description                |
| ------------ | -------------------------- |
| $mod + SPACE | Cycle input method (fcitx) |

### Window

| Keys                        | Description                    |
| --------------------------- | ------------------------------ |
| $mod + V                    | Toggle float                   |
| $mod + P                    | Toggle pseudo #dwindle         |
| $mod + S                    | Toggle split #dwindle          |
| $mod + N                    | Toggle Transparency            |
| $mod + SHIFT + C            | Center window                  |
| $mod + (h/j/k/l)            | Move focus left/down/up/right  |
| $mod + SHIFT + (h/j/k/l)    | Move window left/down/up/right |
| ALT + TAB                   | Cycle next window and focus    |
| $mod + (Mouse Right Button) | Resize Window                  |
| $mod + (Mouse Left Button)  | Move Window                    |
| CTRL + $mod + (h/j/k/l)     | Resize Window                  |
| F11                         | Toggle Fullscreen              |

### Utilities

| Keys                    | Description                          |
| ----------------------- | ------------------------------------ |
| CTRL + $mod + P         | Bitwarden Selector                   |
| $mod + PERIOD           | Emoji Selector                       |
| $mod + SHIFT + S        | Screenshot (region)                  |
| CTRL + SHIFT + S        | Screenshot (window)                  |
| CTRL + SHIFT + $mod + S | Screenshot (monitor)                 |
| CTRL + ALT + S          | Screenshot (Active Window)           |
| CTRL + $mod + C         | Calculator                           |
| $mod + SHIFT + P        | Color Picker                         |
| All (Media Keys)        | Media keys work just like media keys |
| CTRL + $mod + COMMA     | Previous Media                       |
| CTRL + $mod + PERIOD    | Next Media                           |

---

## Workspaces

> Workspace \[G\] is for \[G\]aming workspace, which binds to workspace 7

| Keys                         | Description                                    |
| ---------------------------- | ---------------------------------------------- |
| $mod + (1~9)                 | Switch to workspace (1~9)                      |
| $mod + SHIFT + (1~9)         | Move window to workspace (1~9)                 |
| $mod + G                     | Switch to \[G\]aming workspace (7)             |
| $mod + (mouse wheel up/down) | Next workspace (workspaces on current monitor) |

### Special Rules

- Workspace is binding to your seperator monitors, for example:

  You have `DP-0` and `DP-1` two monitors, and `DP-0` is your main monitor.
  Then, workspace \[1 3 5 7 9\] is bind to `DP-0`, and the rest workspaces \[2 4
  6 8\] is bind to `DP-1`.

## Window Rules

Window rules are defined in [windowrule.nix](../home/user/hypr/windowrule.nix).
The worth mentioning fules:

- Discord: bind to workspace `4`
- Steam: bind to workspace `7` (which is workspace `G` also)
