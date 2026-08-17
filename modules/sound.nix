{
  flake.modules.nixos.gui = {
    # Pipewire real-time access
    security.rtkit.enable = true;

    services = {
      pulseaudio.enable = false;

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
        audio.enable = true;
      };

      playerctld.enable = true;
    };
  };
}
