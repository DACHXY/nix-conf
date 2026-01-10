{ pkgs, ... }:
{
  programs = {
    obs-studio = {
      enable = true;
      enableVirtualCamera = false; # Handled by webcam.nix
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
      ];
    };
  };
}
