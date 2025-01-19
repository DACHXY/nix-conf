{ pkgs, ... }:

{
  security.rtkit.enable = true; # Pipewire real-time access
  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
    audio.enable = true;
  };

  services.playerctld.enable = true;

  environment.systemPackages = with pkgs; [
    pavucontrol
    playerctl
  ];
}
