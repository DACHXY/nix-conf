{ pkgs, lib, inputs, system, cursor-size, ... }:

let
  startScript = import ./hypr/exec.nix { inherit pkgs lib inputs system; };
  mainMod = "SUPER";
  window = import ./hypr/window.nix;
  windowrule = import ./hypr/windowrule.nix;
  input = import ./hypr/input.nix;
  plugins = import ./hypr/plugin.nix;
  cursorSize = cursor-size;
  cursorName = "catppuccin-macchiato-lavender-cursors";
in
{
  home.packages = with pkgs; [
    hyprpaper
    hyprcursor
  ];

  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false;
    package = inputs.hyprland.packages.${system}.hyprland;

    plugins = (with inputs.hyprland-plugins.packages.${system}; [
      xtra-dispatchers
      hyprexpo
      hyprwinwrap
    ]) ++ ([
      inputs.hyprgrass.packages.${system}.default
    ]);

    settings = {
      bind = import ./hypr/bind.nix { inherit mainMod; };
      bindm = import ./hypr/bindm.nix { inherit mainMod; };
      monitor = import ./hypr/monitor.nix;
      plugin = plugins;
      exec-once = ''${startScript}'';
      env = [
        ''HYPRCURSOR_THEME, ${cursorName}''
        ''HYPRCURSOR_SIZE, ${cursorSize}''
        ''XCURSOR_THEME, ${cursorName}''
        ''XCURSOR_SIZE, ${cursorSize}''
      ];
    } // window // windowrule // input;
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "~/.config/wallpapers/wall.png" ];
      wallpaper = [ ", ~/.config/wallpapers/wall.png" ];
      splash = false;
      ipc = "on";
    };
  };
}
