{ pkgs, ... }:

{
  services = {
    displayManager = {
      sddm.wayland.enable = true;
      sddm.enable = true;
      sddm.theme = "${import ./sddm-theme.nix { inherit pkgs; }}";
    };
  };
}
