{ pkgs, lib, inputs, system, ... }:

let
  startScript = import ./hypr/exec.nix { inherit pkgs lib inputs system; };
  mainMod = "SUPER";
  window = import ./hypr/window.nix;
  windowrule = import ./hypr/windowrule.nix;
  input = import ./hypr/input.nix;
  plugins = import ./hypr/plugin.nix;
in
{

  home.packages = with pkgs; [
    hyprpaper
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
