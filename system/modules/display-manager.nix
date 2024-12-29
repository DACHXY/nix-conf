{ pkgs, ... }:

{
  services = {
    greetd = {
      enable = false;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --cmd Hyprland";
          user = "danny";
        };
      };
    };

    displayManager = {
      sddm.wayland.enable = true;
      sddm.enable = true;
      sddm.theme = "${import ./sddm-theme.nix { inherit pkgs; }}";
    };
  };

  environment.systemPackages = with pkgs; [
    greetd.tuigreet
  ];
}
